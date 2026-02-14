"""
Route-optimization API endpoint
───────────────────────────────
POST /optimize-route

Accepts a list of (product_id, quantity) items, runs the
RouteOptimizer engine, and returns JSON with full paths,
distances, elevator usage, assigned locations, etc.
"""

from fastapi import APIRouter, HTTPException
from pathlib import Path
import traceback

from ..schemas.route_request import (
    RouteOptimizationRequest,
    RouteOptimizationResponse,
    RouteResult,
    RouteSummary,
    LegDetail,
)
from ...config.logging_config import get_logger

logger = get_logger("route_routes")
router = APIRouter()

# ── Lazy-loaded singleton ───────────────────────────────────────────
_optimizer = None


def _get_optimizer():
    """Build the RouteOptimizer once (heavy init: grids, BFS, inventory)."""
    global _optimizer
    if _optimizer is None:
        # Import here so the module-level import path stays clean
        import sys

        # The RouteOptimizer lives in ai/notebooks/routeOpt/
        _route_opt_dir = Path(__file__).resolve().parents[2] / "notebooks" / "routeOpt"
        if str(_route_opt_dir) not in sys.path:
            sys.path.insert(0, str(_route_opt_dir))

        from route_optimizer import RouteOptimizer  # type: ignore

        logger.info("Initializing RouteOptimizer (one-time) …")
        _optimizer = RouteOptimizer()
        logger.info("RouteOptimizer ready")
    return _optimizer


def _convert_result(raw: dict) -> RouteResult:
    """Map the dict returned by RouteOptimizer into a RouteResult schema."""

    # Error case
    if "error" in raw:
        return RouteResult(
            product_id=raw.get("product_id", "?"),
            requested_qty=raw.get("requested_qty", 0),
            candidate_slots=raw.get("candidate_slots"),
            error=raw["error"],
        )

    source = raw["source"]  # (floor, row, col)

    # Paths — convert tuples to lists for JSON
    leg1 = [[int(f), int(r), int(c)] for f, r, c in raw.get("leg1_path", [])]
    leg3 = [[int(f), int(r), int(c)] for f, r, c in raw.get("leg3_path", [])]

    elevator_cost = int(raw.get("leg2_cost", 0))
    walk1 = len(raw.get("leg1_path", []))
    walk3 = len(raw.get("leg3_path", []))
    total = int(raw.get("total_cost", 0))

    src_chariot = list(raw["src_chariot"]) if raw.get("src_chariot") else None
    gf_chariot  = list(raw["gf_chariot"])  if raw.get("gf_chariot")  else None

    access_pt = list(raw["access_point"]) if raw.get("access_point") else None

    floors_traversed = int(source[0]) if source[0] else 0

    # Build legs breakdown
    legs = [
        LegDetail(leg="walk_to_chariot",   path=leg1, distance=walk1),
        LegDetail(leg="elevator",          path=None, distance=elevator_cost),
        LegDetail(leg="walk_to_target",    path=leg3, distance=walk3),
    ]

    return RouteResult(
        product_id=raw.get("product_id", "?"),
        requested_qty=raw.get("requested_qty", 0),
        available_qty=raw.get("available_qty"),
        candidate_slots=raw.get("candidate_slots"),
        emplacement_id=raw.get("emplacement_id"),
        emplacement_code=raw.get("emplacement_code"),
        source_floor=int(source[0]),
        source_row=int(source[1]),
        source_col=int(source[2]),
        source_slot_id=raw.get("source_slot_id"),
        target_slot_id=raw.get("target_slot_id"),
        target_type=raw.get("target_type"),
        access_point=access_pt,
        elevator_cost=elevator_cost,
        walk_to_chariot_distance=walk1,
        walk_to_target_distance=walk3,
        total_cost=total,
        used_elevator=elevator_cost > 0,
        elevator_floors_traversed=floors_traversed,
        leg1_path=leg1,
        leg3_path=leg3,
        src_chariot=src_chariot,
        gf_chariot=gf_chariot,
        legs=legs,
        error=None,
    )


@router.post("/optimize-route", response_model=RouteOptimizationResponse)
async def optimize_route(request: RouteOptimizationRequest):
    """
    Find optimal picking routes from storage floors to the ground floor.

    **Input** — list of `{product_id, quantity}` items.\n
    **Output** — per-product routes with full (floor, row, col) paths,
    distances, elevator usage, assigned slots, and an aggregate summary.
    """
    logger.info(
        f"POST /optimize-route — {len(request.items)} items, "
        f"target_type={request.target_type}"
    )

    try:
        opt = _get_optimizer()

        product_ids = [item.product_id for item in request.items]
        quantities  = [item.quantity   for item in request.items]

        raw_results = opt.find_routes_by_products(
            product_ids, quantities, target_type=request.target_type
        )

        routes: list[RouteResult] = [_convert_result(r) for r in raw_results]

        # Aggregate summary
        routed = sum(1 for r in routes if r.error is None)
        failed = len(routes) - routed

        total_cost      = sum(r.total_cost or 0 for r in routes if r.error is None)
        total_elevator   = sum(r.elevator_cost or 0 for r in routes if r.error is None)
        total_walk       = sum(
            (r.walk_to_chariot_distance or 0) + (r.walk_to_target_distance or 0)
            for r in routes if r.error is None
        )

        summary = RouteSummary(
            total_items=len(routes),
            routed=routed,
            failed=failed,
            total_cost=total_cost,
            total_elevator_cost=total_elevator,
            total_walk_distance=total_walk,
        )

        return RouteOptimizationResponse(
            success=True,
            summary=summary,
            routes=routes,
        )

    except Exception as e:
        logger.error(f"Error in optimize-route: {traceback.format_exc()}")
        raise HTTPException(status_code=500, detail=str(e))
