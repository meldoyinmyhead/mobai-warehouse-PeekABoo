"""
Standalone FastAPI server for route optimization.
Run directly:  python route_api.py
Docs:  http://localhost:8001/docs

POST /optimize-route  — accepts a list of products + quantities,
returns full routes with paths, distances, elevator usage, etc.
"""

import sys
import traceback
from pathlib import Path
from typing import List, Optional

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
import uvicorn

# ── Make sure route_optimizer.py is importable ──────────────────────
_THIS_DIR = Path(__file__).resolve().parent
if str(_THIS_DIR) not in sys.path:
    sys.path.insert(0, str(_THIS_DIR))

from route_optimizer import RouteOptimizer  # type: ignore


# ═══════════════════════════════════════════════════════════════════
#  Pydantic schemas
# ═══════════════════════════════════════════════════════════════════

class OrderItem(BaseModel):
    product_id: str = Field(..., examples=["31496"])
    quantity: int   = Field(1, ge=1)

class RouteRequest(BaseModel):
    items: List[OrderItem] = Field(..., min_length=1)
    target_type: str = Field("shelf", description="'shelf', 'exhibition', or 'all'")

class LegDetail(BaseModel):
    leg: str
    path: Optional[List[List[int]]] = None
    distance: int

class RouteResult(BaseModel):
    product_id: str
    requested_qty: int
    available_qty: Optional[int]         = None
    candidate_slots: Optional[int]       = None
    emplacement_id: Optional[str]        = None
    emplacement_code: Optional[str]      = None

    source_floor: Optional[int]          = None
    source_row: Optional[int]            = None
    source_col: Optional[int]            = None
    source_slot_id: Optional[str]        = None

    target_slot_id: Optional[str]        = None
    target_type: Optional[str]           = None
    access_point: Optional[List[int]]    = None

    elevator_cost: Optional[int]         = None
    walk_to_chariot_distance: Optional[int] = None
    walk_to_target_distance: Optional[int]  = None
    total_cost: Optional[int]            = None

    used_elevator: bool                  = False
    elevator_floors_traversed: Optional[int] = None

    leg1_path: Optional[List[List[int]]] = None
    leg3_path: Optional[List[List[int]]] = None
    src_chariot: Optional[List[int]]     = None
    gf_chariot: Optional[List[int]]      = None
    legs: Optional[List[LegDetail]]      = None

    error: Optional[str]                 = None

class RouteSummary(BaseModel):
    total_items: int
    routed: int
    failed: int
    total_cost: int
    total_elevator_cost: int
    total_walk_distance: int

class RouteResponse(BaseModel):
    success: bool
    summary: RouteSummary
    routes: List[RouteResult]


# ═══════════════════════════════════════════════════════════════════
#  App + single-instance optimizer
# ═══════════════════════════════════════════════════════════════════

app = FastAPI(
    title="Warehouse Route Optimization API",
    version="1.0.0",
    description="Find optimal picking routes from storage floors to the ground floor.",
)

_optimizer: RouteOptimizer | None = None


@app.on_event("startup")
async def _warm_up():
    """Pre-load the heavy RouteOptimizer at server start."""
    global _optimizer
    print("⏳ Building warehouse model …")
    _optimizer = RouteOptimizer()
    print("✓ RouteOptimizer ready")


def _convert(raw: dict) -> RouteResult:
    if "error" in raw:
        return RouteResult(
            product_id=raw.get("product_id", "?"),
            requested_qty=raw.get("requested_qty", 0),
            candidate_slots=raw.get("candidate_slots"),
            error=raw["error"],
        )

    src = raw["source"]
    leg1 = [[int(f), int(r), int(c)] for f, r, c in raw.get("leg1_path", [])]
    leg3 = [[int(f), int(r), int(c)] for f, r, c in raw.get("leg3_path", [])]

    elev_cost = int(raw.get("leg2_cost", 0))
    w1 = len(raw.get("leg1_path", []))
    w3 = len(raw.get("leg3_path", []))
    total = int(raw.get("total_cost", 0))
    floors = int(src[0]) if src[0] else 0

    return RouteResult(
        product_id=raw.get("product_id", "?"),
        requested_qty=raw.get("requested_qty", 0),
        available_qty=raw.get("available_qty"),
        candidate_slots=raw.get("candidate_slots"),
        emplacement_id=raw.get("emplacement_id"),
        emplacement_code=raw.get("emplacement_code"),
        source_floor=int(src[0]),
        source_row=int(src[1]),
        source_col=int(src[2]),
        source_slot_id=raw.get("source_slot_id"),
        target_slot_id=raw.get("target_slot_id"),
        target_type=raw.get("target_type"),
        access_point=list(raw["access_point"]) if raw.get("access_point") else None,
        elevator_cost=elev_cost,
        walk_to_chariot_distance=w1,
        walk_to_target_distance=w3,
        total_cost=total,
        used_elevator=elev_cost > 0,
        elevator_floors_traversed=floors,
        leg1_path=leg1,
        leg3_path=leg3,
        src_chariot=list(raw["src_chariot"]) if raw.get("src_chariot") else None,
        gf_chariot=list(raw["gf_chariot"])  if raw.get("gf_chariot")  else None,
        legs=[
            LegDetail(leg="walk_to_chariot", path=leg1, distance=w1),
            LegDetail(leg="elevator",        path=None, distance=elev_cost),
            LegDetail(leg="walk_to_target",  path=leg3, distance=w3),
        ],
    )


# ═══════════════════════════════════════════════════════════════════
#  Endpoint
# ═══════════════════════════════════════════════════════════════════

@app.post("/optimize-route", response_model=RouteResponse)
async def optimize_route(request: RouteRequest):
    """
    **Input** — list of `{product_id, quantity}` items.

    **Output** — per-product routes with:
    - Full `(floor, row, col)` path from storage slot → chariot → ground-floor target
    - Distances for each leg (walk + elevator)
    - Elevator usage flag & floors traversed
    - Source & target slot IDs / emplacement codes
    - Aggregate summary (routed / failed / total cost)
    """
    try:
        assert _optimizer is not None, "Optimizer not initialized"

        ids  = [it.product_id for it in request.items]
        qtys = [it.quantity   for it in request.items]

        raw = _optimizer.find_routes_by_products(ids, qtys, target_type=request.target_type)
        routes = [_convert(r) for r in raw]

        ok   = [r for r in routes if r.error is None]
        fail = len(routes) - len(ok)

        summary = RouteSummary(
            total_items=len(routes),
            routed=len(ok),
            failed=fail,
            total_cost=sum(r.total_cost or 0 for r in ok),
            total_elevator_cost=sum(r.elevator_cost or 0 for r in ok),
            total_walk_distance=sum(
                (r.walk_to_chariot_distance or 0) + (r.walk_to_target_distance or 0)
                for r in ok
            ),
        )

        return RouteResponse(success=True, summary=summary, routes=routes)

    except Exception as e:
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


# ═══════════════════════════════════════════════════════════════════
if __name__ == "__main__":
    uvicorn.run("route_api:app", host="127.0.0.1", port=8001, reload=False)
