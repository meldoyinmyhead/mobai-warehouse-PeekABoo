"""
Standalone FastAPI server for storage assignment.
Run directly:  python storage_api.py
Docs:  http://localhost:8002/docs

POST /assign-storage  — accepts a list of products + quantities,
returns assigned slots with paths, distances, elevator usage, etc.
"""

import sys
import copy
import traceback
from pathlib import Path
from typing import List, Optional
from collections import Counter

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
import uvicorn

# ── Make sure storage_assignment.py is importable ───────────────────
_THIS_DIR = Path(__file__).resolve().parent
if str(_THIS_DIR) not in sys.path:
    sys.path.insert(0, str(_THIS_DIR))

from storage_assignment import WarehouseOptimizer  # type: ignore


# ═══════════════════════════════════════════════════════════════════
#  Pydantic schemas
# ═══════════════════════════════════════════════════════════════════

class StorageItem(BaseModel):
    product_id: str = Field(..., examples=["31851"])
    quantity: int   = Field(1, ge=1)

class StorageRequest(BaseModel):
    items: List[StorageItem] = Field(..., min_length=1)
    mode: str = Field("greedy", description="'greedy' or 'milp'")
    slot_capacity_cap: Optional[float] = Field(
        None, ge=0.001,
        description="Cap each slot capacity (m³) — null = real capacity",
    )

class JourneyDetail(BaseModel):
    start: str
    elevator_from: int
    elevator_to: int
    elevator_distance: int
    walk_from: str
    walk_to: str
    walk_distance: int
    total_distance: int
    walk_path: Optional[List[List[int]]] = None

class AssignmentResult(BaseModel):
    product_id: str
    unit: int
    total_units: int

    product_name: Optional[str]            = None
    category: Optional[str]                = None
    abc_class: Optional[str]               = None
    product_volume_m3: Optional[float]     = None
    product_weight_kg: Optional[float]     = None
    demand_frequency: Optional[float]      = None
    reception_frequency: Optional[float]   = None

    emplacement_code: Optional[str]        = None
    emplacement_id: Optional[str]          = None
    floor: Optional[int]                   = None
    row: Optional[int]                     = None
    col: Optional[int]                     = None

    placement_cost: Optional[float]        = None
    elevator_cost: Optional[int]           = None
    walk_distance: Optional[int]           = None
    total_distance: Optional[int]          = None
    remaining_capacity_m3: Optional[float] = None

    used_elevator: bool                    = False
    elevator_floors_traversed: Optional[int] = None

    journey: Optional[JourneyDetail]       = None
    path: Optional[List[List[int]]]        = None

    error: Optional[str]                   = None

class AssignmentSummary(BaseModel):
    total_items: int
    total_units: int
    assigned: int
    skipped: int
    total_placement_cost: float
    total_travel_distance: int
    total_elevator_distance: int
    total_walk_distance: int
    unique_slots_used: int
    floor_distribution: dict
    mode: str

class StorageResponse(BaseModel):
    success: bool
    summary: AssignmentSummary
    assignments: List[AssignmentResult]
    skipped: List[dict] = Field(default_factory=list)


# ═══════════════════════════════════════════════════════════════════
#  App + single-instance optimizer
# ═══════════════════════════════════════════════════════════════════

app = FastAPI(
    title="Warehouse Storage Assignment API",
    version="1.0.0",
    description="Assign optimal storage slots for incoming products.",
)

_optimizer: WarehouseOptimizer | None = None


@app.on_event("startup")
async def _warm_up():
    global _optimizer
    print("⏳ Building warehouse model …")
    _optimizer = WarehouseOptimizer()
    print(f"✓ Ready — {len(_optimizer.product_features)} products, "
          f"{len(_optimizer.slot_meta)} storage cells")


def _convert(
    raw: dict | None,
    product_id: str,
    unit: int,
    total_units: int,
    features: dict | None,
    error_reason: str | None = None,
) -> AssignmentResult:
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


# ═══════════════════════════════════════════════════════════════════
#  Endpoint
# ═══════════════════════════════════════════════════════════════════

@app.post("/assign-storage", response_model=StorageResponse)
async def assign_storage(request: StorageRequest):
    """
    **Input** — list of `{product_id, quantity}` items + mode.\n
    **Output** — per-unit assignments with:
    - Assigned slot (emplacement code, floor, row, col)
    - Full walk path as `(row, col)` waypoints on the floor
    - Journey breakdown (elevator + walk distances)
    - Product attributes (name, category, ABC class, volume, weight, demand/reception freq)
    - Placement cost and remaining slot capacity
    - Aggregate summary (assigned / skipped / total distances / floor distribution)
    """
    try:
        assert _optimizer is not None, "Optimizer not initialized"

        _optimizer.reset()

        # Optional capacity cap for demo
        if request.slot_capacity_cap is not None:
            cap = request.slot_capacity_cap
            for key in _optimizer.slot_meta:
                _optimizer.slot_meta[key]["remaining_m3"] = cap
                _optimizer.slot_meta[key]["total_capacity_m3"] = cap
                _optimizer.slot_meta[key]["used_m3"] = 0.0
            _optimizer._initial_slot_meta = copy.deepcopy(_optimizer.slot_meta)
            for floor in _optimizer.available_targets:
                for t in _optimizer.available_targets[floor]:
                    t["available_m3"] = cap

        assignments: list[AssignmentResult] = []
        skipped_list: list[dict] = []

        if request.mode == "milp":
            all_pids = []
            unit_map = []
            for item in request.items:
                for u in range(1, item.quantity + 1):
                    all_pids.append(item.product_id)
                    unit_map.append((u, item.quantity))

            raw_results = _optimizer.optimize_batch_assignment(
                all_pids, update_capacity=True
            )

            for idx, raw in enumerate(raw_results):
                pid = all_pids[idx]
                unit_no, total = unit_map[idx]
                feat = _optimizer.product_features.get(pid)
                if raw is None:
                    assignments.append(_convert(None, pid, unit_no, total, feat, "No feasible slot"))
                    skipped_list.append({"product_id": pid, "unit": unit_no, "reason": "No feasible slot"})
                else:
                    assignments.append(_convert(raw, pid, unit_no, total, feat))
        else:
            for item in request.items:
                for unit_no in range(1, item.quantity + 1):
                    feat = _optimizer.product_features.get(item.product_id)
                    raw = _optimizer.find_best_slot(item.product_id, update_capacity=True)
                    if raw is None:
                        reason = (
                            "Product not found"
                            if item.product_id not in _optimizer.product_features
                            else "No capacity available"
                        )
                        assignments.append(_convert(None, item.product_id, unit_no, item.quantity, feat, reason))
                        skipped_list.append({"product_id": item.product_id, "unit": unit_no, "reason": reason})
                    else:
                        assignments.append(_convert(raw, item.product_id, unit_no, item.quantity, feat))

        ok = [a for a in assignments if a.error is None]
        floor_dist = dict(Counter(a.floor for a in ok))
        unique_slots = set(a.emplacement_code for a in ok)

        summary = AssignmentSummary(
            total_items=len(request.items),
            total_units=sum(it.quantity for it in request.items),
            assigned=len(ok),
            skipped=len(skipped_list),
            total_placement_cost=round(sum(a.placement_cost or 0 for a in ok), 4),
            total_travel_distance=sum(a.total_distance or 0 for a in ok),
            total_elevator_distance=sum(a.elevator_cost or 0 for a in ok),
            total_walk_distance=sum(a.walk_distance or 0 for a in ok),
            unique_slots_used=len(unique_slots),
            floor_distribution=floor_dist,
            mode=request.mode,
        )

        return StorageResponse(
            success=True, summary=summary,
            assignments=assignments, skipped=skipped_list,
        )

    except Exception as e:
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


# ═══════════════════════════════════════════════════════════════════
if __name__ == "__main__":
    uvicorn.run("storage_api:app", host="127.0.0.1", port=8002, reload=False)
