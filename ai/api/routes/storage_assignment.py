"""
Storage-assignment API endpoint (AI service integration)
────────────────────────────────────────────────────────
POST /assign-storage

Accepts a list of (product_id, quantity) items, runs the
WarehouseOptimizer engine, and returns JSON with assigned slots,
paths, distances, elevator usage, product info, etc.
"""

from fastapi import APIRouter, HTTPException
from pathlib import Path
import traceback
import copy

from ..schemas.storage_assignment_request import (
    StorageAssignmentRequest,
    StorageAssignmentResponse,
    AssignmentResult,
    AssignmentSummary,
    JourneyDetail,
)
from ...config.logging_config import get_logger

logger = get_logger("storage_assignment_routes")
router = APIRouter()

# ── Lazy-loaded singleton ───────────────────────────────────────────
_optimizer = None


def _get_optimizer():
    """Build the WarehouseOptimizer once (heavy init: grids, BFS, features)."""
    global _optimizer
    if _optimizer is None:
        import sys
        _storage_opt_dir = Path(__file__).resolve().parents[2] / "notebooks" / "storageOpt"
        if str(_storage_opt_dir) not in sys.path:
            sys.path.insert(0, str(_storage_opt_dir))

        from storage_assignment import WarehouseOptimizer  # type: ignore

        logger.info("Initializing WarehouseOptimizer (one-time) …")
        _optimizer = WarehouseOptimizer()
        logger.info("WarehouseOptimizer ready")
    return _optimizer


def _convert_result(
    raw: dict | None,
    product_id: str,
    unit: int,
    total_units: int,
    features: dict | None,
    error_reason: str | None = None,
) -> AssignmentResult:
    """Map the dict returned by WarehouseOptimizer into an AssignmentResult."""

    if raw is None or error_reason:
        return AssignmentResult(
            product_id=product_id,
            unit=unit,
            total_units=total_units,
            error=error_reason or "No feasible slot found",
        )

    floor = raw["floor"]
    pos = raw["position"]
    path_tuples = raw.get("path") or []
    path_lists = [[int(r), int(c)] for r, c in path_tuples]

    walk_dist = int(raw.get("walk_distance", -1))
    elev_cost = int(raw.get("elevator_cost", 0))
    total_dist = int(raw.get("total_distance", -1))

    journey = JourneyDetail(
        start="Ground Floor (0) — Receiving zone",
        elevator_from=0,
        elevator_to=floor,
        elevator_distance=elev_cost,
        walk_from=f"Chariot exit on Floor {floor}",
        walk_to=raw.get("emplacement_code", "?"),
        walk_distance=walk_dist,
        total_distance=total_dist,
        walk_path=path_lists if path_lists else None,
    )

    return AssignmentResult(
        product_id=product_id,
        unit=unit,
        total_units=total_units,
        product_name=str(features.get("nom", "")) if features else None,
        category=str(features.get("categorie", "")) if features else None,
        abc_class=raw.get("abc_class"),
        product_volume_m3=raw.get("product_volume_m3"),
        product_weight_kg=features.get("weight_kg") if features else None,
        demand_frequency=features.get("demand_freq") if features else None,
        reception_frequency=features.get("reception_freq") if features else None,
        emplacement_code=raw.get("emplacement_code"),
        emplacement_id=str(raw.get("id_emplacement", "")),
        floor=floor,
        row=int(pos[0]),
        col=int(pos[1]),
        placement_cost=raw.get("cost"),
        elevator_cost=elev_cost,
        walk_distance=walk_dist,
        total_distance=total_dist,
        remaining_capacity_m3=raw.get("remaining_capacity_m3"),
        used_elevator=floor > 0,
        elevator_floors_traversed=floor,
        journey=journey,
        path=path_lists if path_lists else None,
    )


@router.post("/assign-storage", response_model=StorageAssignmentResponse)
async def assign_storage(request: StorageAssignmentRequest):
    """
    Assign optimal storage slots for incoming products.

    **Input** — list of `{product_id, quantity}` items + optional mode.\n
    **Output** — per-unit assignments with full paths, distances,
    elevator usage, product attributes, and an aggregate summary.
    """
    logger.info(
        f"POST /assign-storage — {len(request.items)} lines, mode={request.mode}"
    )

    try:
        opt = _get_optimizer()
        opt.reset()

        # Optional capacity cap
        if request.slot_capacity_cap is not None:
            cap = request.slot_capacity_cap
            for key in opt.slot_meta:
                opt.slot_meta[key]["remaining_m3"] = cap
                opt.slot_meta[key]["total_capacity_m3"] = cap
                opt.slot_meta[key]["used_m3"] = 0.0
            opt._initial_slot_meta = copy.deepcopy(opt.slot_meta)
            for floor in opt.available_targets:
                for t in opt.available_targets[floor]:
                    t["available_m3"] = cap

        assignments: list[AssignmentResult] = []
        skipped_list: list[dict] = []

        if request.mode == "milp":
            # Flatten to one entry per unit for MILP
            all_pids = []
            unit_map = []
            for item in request.items:
                for u in range(1, item.quantity + 1):
                    all_pids.append(item.product_id)
                    unit_map.append((u, item.quantity))

            raw_results = opt.optimize_batch_assignment(
                all_pids, update_capacity=True
            )

            for idx, raw in enumerate(raw_results):
                pid = all_pids[idx]
                unit_no, total = unit_map[idx]
                feat = opt.product_features.get(pid)
                if raw is None:
                    assignments.append(_convert_result(
                        None, pid, unit_no, total, feat, "No feasible slot"
                    ))
                    skipped_list.append({"product_id": pid, "unit": unit_no, "reason": "No feasible slot"})
                else:
                    assignments.append(_convert_result(raw, pid, unit_no, total, feat))
        else:
            # Greedy sequential
            for item in request.items:
                for unit_no in range(1, item.quantity + 1):
                    feat = opt.product_features.get(item.product_id)
                    raw = opt.find_best_slot(item.product_id, update_capacity=True)
                    if raw is None:
                        reason = (
                            "Product not found" if item.product_id not in opt.product_features
                            else "No capacity available"
                        )
                        assignments.append(_convert_result(
                            None, item.product_id, unit_no, item.quantity, feat, reason
                        ))
                        skipped_list.append({
                            "product_id": item.product_id,
                            "unit": unit_no,
                            "reason": reason,
                        })
                    else:
                        assignments.append(_convert_result(
                            raw, item.product_id, unit_no, item.quantity, feat
                        ))

        # Build summary
        ok = [a for a in assignments if a.error is None]
        from collections import Counter
        floor_dist = dict(Counter(a.floor for a in ok))
        unique_slots = set(a.emplacement_code for a in ok)

        summary = AssignmentSummary(
            total_items=len(request.items),
            total_units=sum(it.quantity for it in request.items),
            assigned=len(ok),
            skipped=len(skipped_list),
            total_placement_cost=sum(a.placement_cost or 0 for a in ok),
            total_travel_distance=sum(a.total_distance or 0 for a in ok),
            total_elevator_distance=sum(a.elevator_cost or 0 for a in ok),
            total_walk_distance=sum(a.walk_distance or 0 for a in ok),
            unique_slots_used=len(unique_slots),
            floor_distribution=floor_dist,
            mode=request.mode,
        )

        return StorageAssignmentResponse(
            success=True,
            summary=summary,
            assignments=assignments,
            skipped=skipped_list,
        )

    except Exception as e:
        logger.error(f"Error in assign-storage: {traceback.format_exc()}")
        raise HTTPException(status_code=500, detail=str(e))
