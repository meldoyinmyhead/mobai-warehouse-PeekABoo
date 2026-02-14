"""
Combined Warehouse API — Route Optimization + Storage Assignment
================================================================
Run:   python warehouse_api.py
Docs:  http://localhost:8000/docs

Endpoints:
  POST /optimize-route    — find picking routes from storage → ground floor
  POST /assign-storage    — assign optimal storage slots for incoming products
"""

import sys
import copy
import traceback
from pathlib import Path
from typing import List, Optional
from collections import Counter

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
import uvicorn

# ── Make both optimizer modules importable ──────────────────────────
_THIS_DIR = Path(__file__).resolve().parent
_ROUTE_OPT_DIR = (_THIS_DIR / "routeOpt").resolve()
_STORAGE_OPT_DIR = (_THIS_DIR / "storageOpt").resolve()

for p in [str(_ROUTE_OPT_DIR), str(_STORAGE_OPT_DIR)]:
    if p not in sys.path:
        sys.path.insert(0, p)


# ═══════════════════════════════════════════════════════════════════
#  SCHEMAS — Route Optimization
# ═══════════════════════════════════════════════════════════════════

class RouteOrderItem(BaseModel):
    product_id: str = Field(..., examples=["31496"])
    quantity: int   = Field(1, ge=1)

class RouteRequest(BaseModel):
    items: List[RouteOrderItem] = Field(..., min_length=1)
    target_type: str = Field("shelf", description="'shelf', 'exhibition', or 'all'")

class RouteLegDetail(BaseModel):
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
    legs: Optional[List[RouteLegDetail]] = None

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
#  SCHEMAS — Storage Assignment
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
#  SCHEMAS — Storage Path Computation
# ═══════════════════════════════════════════════════════════════════

class PathItem(BaseModel):
    product_id: str = Field(..., examples=["31851"])
    quantity: int   = Field(1, ge=1)

class PathRequest(BaseModel):
    items: List[PathItem] = Field(..., min_length=1)

class ProductPathDetail(BaseModel):
    product_id: str
    unit: int
    total_units: int
    category: Optional[str] = None
    abc_class: Optional[str] = None
    
    # Source information (receiving zone)
    source: str = "Ground Floor (0) - Receiving Zone"
    
    # Target information (assigned slot)
    target_slot: Optional[str] = None
    target_floor: Optional[int] = None
    target_position: Optional[dict] = None  # {"row": int, "col": int}
    
    # Distance breakdown
    elevator_distance: Optional[int] = None
    walk_distance: Optional[int] = None
    total_distance: Optional[int] = None
    
    # Full path (list of [row, col] coordinates on target floor)
    path: Optional[List[List[int]]] = None
    
    # Cost metrics
    placement_cost: Optional[float] = None
    
    # Journey summary
    journey_summary: Optional[str] = None
    
    # Error if assignment failed
    error: Optional[str] = None

class PathSummary(BaseModel):
    total_products: int
    total_units: int
    successfully_assigned: int
    failed: int
    total_distance: int
    total_elevator_distance: int
    total_walk_distance: int
    unique_slots_used: int
    floor_distribution: dict

class PathResponse(BaseModel):
    success: bool
    summary: PathSummary
    paths: List[ProductPathDetail]


# ═══════════════════════════════════════════════════════════════════
#  APP
# ═══════════════════════════════════════════════════════════════════

app = FastAPI(
    title="MobAI Warehouse Optimization API",
    version="1.0.0",
    description=(
        "Combined API for warehouse operations:\n\n"
        "- **Route Optimization** — find optimal picking routes (storage → ground floor)\n"
        "- **Storage Assignment** — assign optimal storage slots for incoming products"
    ),
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Lazy singletons ────────────────────────────────────────────────
_route_optimizer = None
_storage_optimizer = None


@app.on_event("startup")
async def _warm_up():
    global _route_optimizer, _storage_optimizer

    from route_optimizer import RouteOptimizer        # type: ignore
    from storage_assignment import WarehouseOptimizer  # type: ignore

    print("⏳ Building warehouse models …")

    print("   • RouteOptimizer …")
    _route_optimizer = RouteOptimizer()
    print("   ✓ RouteOptimizer ready")

    print("   • WarehouseOptimizer …")
    _storage_optimizer = WarehouseOptimizer()
    print(f"   ✓ WarehouseOptimizer ready — "
          f"{len(_storage_optimizer.product_features)} products, "
          f"{len(_storage_optimizer.slot_meta)} cells")

    print("✅ All models loaded\n")


# ═══════════════════════════════════════════════════════════════════
#  HELPERS — Route
# ═══════════════════════════════════════════════════════════════════

def _convert_route(raw: dict) -> RouteResult:
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
            RouteLegDetail(leg="walk_to_chariot", path=leg1, distance=w1),
            RouteLegDetail(leg="elevator",        path=None, distance=elev_cost),
            RouteLegDetail(leg="walk_to_target",  path=leg3, distance=w3),
        ],
    )


# ═══════════════════════════════════════════════════════════════════
#  HELPERS — Storage
# ═══════════════════════════════════════════════════════════════════

def _convert_storage(
    raw: dict | None,
    product_id: str,
    unit: int,
    total_units: int,
    features: dict | None,
    error_reason: str | None = None,
) -> AssignmentResult:
    if raw is None or error_reason:
        return AssignmentResult(
            product_id=product_id, unit=unit, total_units=total_units,
            product_name=str(features.get("nom", "")) if features else None,
            category=str(features.get("categorie", "")) if features else None,
            abc_class=str(features.get("abc_class", "")) if features else None,
            product_volume_m3=features.get("volume_m3") if features else None,
            product_weight_kg=features.get("weight_kg") if features else None,
            demand_frequency=features.get("demand_freq") if features else None,
            reception_frequency=features.get("reception_freq") if features else None,
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
        elevator_from=0, elevator_to=floor,
        elevator_distance=elev_cost,
        walk_from=f"Chariot exit on Floor {floor}",
        walk_to=raw.get("emplacement_code", "?"),
        walk_distance=walk_dist, total_distance=total_dist,
        walk_path=path_lists if path_lists else None,
    )

    return AssignmentResult(
        product_id=product_id, unit=unit, total_units=total_units,
        product_name=str(features.get("nom", "")) if features else None,
        category=str(features.get("categorie", "")) if features else None,
        abc_class=raw.get("abc_class"),
        product_volume_m3=raw.get("product_volume_m3"),
        product_weight_kg=features.get("weight_kg") if features else None,
        demand_frequency=features.get("demand_freq") if features else None,
        reception_frequency=features.get("reception_freq") if features else None,
        emplacement_code=raw.get("emplacement_code"),
        emplacement_id=str(raw.get("id_emplacement", "")),
        floor=floor, row=int(pos[0]), col=int(pos[1]),
        placement_cost=raw.get("cost"),
        elevator_cost=elev_cost, walk_distance=walk_dist,
        total_distance=total_dist,
        remaining_capacity_m3=raw.get("remaining_capacity_m3"),
        used_elevator=floor > 0, elevator_floors_traversed=floor,
        journey=journey,
        path=path_lists if path_lists else None,
    )


# ═══════════════════════════════════════════════════════════════════
#  ENDPOINTS
# ═══════════════════════════════════════════════════════════════════

@app.get("/")
async def root():
    return {
        "service": "MobAI Warehouse Optimization API",
        "endpoints": ["/optimize-route", "/assign-storage", "/compute-storage-paths"],
        "docs": "/docs",
    }


@app.post("/optimize-route", response_model=RouteResponse, tags=["Route Optimization"])
async def optimize_route(request: RouteRequest):
    """
    Find optimal picking routes from storage floors to the ground floor.

    **Input** — list of `{product_id, quantity}` items.\n
    **Output** — per-product routes with full `[floor, row, col]` paths,
    distances, elevator usage, assigned slots, and an aggregate summary.
    """
    try:
        assert _route_optimizer is not None, "RouteOptimizer not initialized"

        ids  = [it.product_id for it in request.items]
        qtys = [it.quantity   for it in request.items]

        raw = _route_optimizer.find_routes_by_products(
            ids, qtys, target_type=request.target_type
        )
        routes = [_convert_route(r) for r in raw]

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


@app.post("/assign-storage", response_model=StorageResponse, tags=["Storage Assignment"])
async def assign_storage(request: StorageRequest):
    """
    Assign optimal storage slots for incoming products.

    **Input** — list of `{product_id, quantity}` items + mode.\n
    **Output** — per-unit assignments with paths, distances,
    elevator usage, product attributes, and an aggregate summary.
    """
    try:
        assert _storage_optimizer is not None, "WarehouseOptimizer not initialized"

        _storage_optimizer.reset()

        # Optional capacity cap — apply TEMPORARILY, never overwrite the
        # original _initial_slot_meta so future reset() restores real data.
        _cap_applied = False
        _saved_available_targets = None
        if request.slot_capacity_cap is not None:
            _cap_applied = True
            cap = request.slot_capacity_cap
            for key in _storage_optimizer.slot_meta:
                _storage_optimizer.slot_meta[key]["remaining_m3"] = cap
                _storage_optimizer.slot_meta[key]["total_capacity_m3"] = cap
                _storage_optimizer.slot_meta[key]["used_m3"] = 0.0
            _saved_available_targets = copy.deepcopy(_storage_optimizer.available_targets)
            for floor in _storage_optimizer.available_targets:
                for t in _storage_optimizer.available_targets[floor]:
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

            raw_results = _storage_optimizer.optimize_batch_assignment(
                all_pids, update_capacity=True
            )
            for idx, raw in enumerate(raw_results):
                pid = all_pids[idx]
                unit_no, total = unit_map[idx]
                feat = _storage_optimizer.product_features.get(pid)
                if raw is None:
                    assignments.append(_convert_storage(None, pid, unit_no, total, feat, "No feasible slot"))
                    skipped_list.append({"product_id": pid, "unit": unit_no, "reason": "No feasible slot"})
                else:
                    assignments.append(_convert_storage(raw, pid, unit_no, total, feat))
        else:
            for item in request.items:
                for unit_no in range(1, item.quantity + 1):
                    feat = _storage_optimizer.product_features.get(item.product_id)
                    raw = _storage_optimizer.find_best_slot(item.product_id, update_capacity=True)
                    if raw is None:
                        if item.product_id not in _storage_optimizer.product_features:
                            reason = "Product not found"
                        elif feat and request.slot_capacity_cap is not None:
                            vol = feat.get("volume_m3", 0)
                            if vol and vol > request.slot_capacity_cap:
                                reason = (f"slot_capacity_cap ({request.slot_capacity_cap} m³) "
                                          f"is smaller than product volume ({vol} m³)")
                            else:
                                reason = "No capacity available"
                        else:
                            reason = "No capacity available"
                        assignments.append(_convert_storage(None, item.product_id, unit_no, item.quantity, feat, reason))
                        skipped_list.append({"product_id": item.product_id, "unit": unit_no, "reason": reason})
                    else:
                        assignments.append(_convert_storage(raw, item.product_id, unit_no, item.quantity, feat))

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

        # Restore original state so cap doesn't persist across requests
        _storage_optimizer.reset()
        if _cap_applied and _saved_available_targets is not None:
            _storage_optimizer.available_targets = _saved_available_targets

        return StorageResponse(
            success=True, summary=summary,
            assignments=assignments, skipped=skipped_list,
        )

    except Exception as e:
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/compute-storage-paths", response_model=PathResponse, tags=["Storage Assignment"])
async def compute_storage_paths(request: PathRequest):
    """
    Compute detailed storage paths for a list of products.
    
    **Input** — list of `{product_id, quantity}` items.
    
    **Output** — detailed path information for each product unit including:
    - Source (receiving zone) and target (assigned slot) locations
    - Complete path with coordinates
    - Distance breakdown (elevator + walking)
    - Floor and position information
    
    Products are assigned to optimal storage slots based on ABC classification,
    demand frequency, and spatial optimization using real warehouse capacity.
    """
    try:
        assert _storage_optimizer is not None, "WarehouseOptimizer not initialized"
        
        # Reset optimizer to fresh state with real capacity
        _storage_optimizer.reset()
        
        paths: list[ProductPathDetail] = []
        
        # Process each product and quantity
        for item in request.items:
            for unit in range(1, item.quantity + 1):
                feat = _storage_optimizer.product_features.get(item.product_id)
                raw = _storage_optimizer.find_best_slot(item.product_id, update_capacity=True)
                
                if raw is None:
                    # Assignment failed
                    reason = "Product not found" if item.product_id not in _storage_optimizer.product_features else "No capacity available"
                    paths.append(ProductPathDetail(
                        product_id=item.product_id,
                        unit=unit,
                        total_units=item.quantity,
                        category=str(feat.get("categorie")) if feat else None,
                        abc_class=str(feat.get("abc_class")) if feat else None,
                        error=reason,
                    ))
                else:
                    # Successful assignment
                    floor = raw["floor"]
                    pos = raw["position"]
                    path_tuples = raw.get("path") or []
                    path_lists = [[int(r), int(c)] for r, c in path_tuples]
                    
                    walk_dist = int(raw.get("walk_distance", 0))
                    elev_dist = int(raw.get("elevator_cost", 0))
                    total_dist = int(raw.get("total_distance", 0))
                    
                    journey_summary = (
                        f"Ground(0) ─elev({elev_dist}m)─▶ "
                        f"Floor {floor} ─walk({walk_dist}m)─▶ "
                        f"{raw.get('emplacement_code', '?')}  │ Total: {total_dist}m"
                    )
                    
                    paths.append(ProductPathDetail(
                        product_id=item.product_id,
                        unit=unit,
                        total_units=item.quantity,
                        category=str(feat.get("categorie")) if feat else None,
                        abc_class=raw.get("abc_class"),
                        target_slot=raw.get("emplacement_code"),
                        target_floor=floor,
                        target_position={"row": int(pos[0]), "col": int(pos[1])},
                        elevator_distance=elev_dist,
                        walk_distance=walk_dist,
                        total_distance=total_dist,
                        path=path_lists if path_lists else None,
                        placement_cost=raw.get("cost"),
                        journey_summary=journey_summary,
                    ))
        
        # Compute summary statistics
        ok = [p for p in paths if p.error is None]
        floor_dist = dict(Counter(p.target_floor for p in ok))
        unique_slots = set(p.target_slot for p in ok)
        
        summary = PathSummary(
            total_products=len(request.items),
            total_units=sum(it.quantity for it in request.items),
            successfully_assigned=len(ok),
            failed=len(paths) - len(ok),
            total_distance=sum(p.total_distance or 0 for p in ok),
            total_elevator_distance=sum(p.elevator_distance or 0 for p in ok),
            total_walk_distance=sum(p.walk_distance or 0 for p in ok),
            unique_slots_used=len(unique_slots),
            floor_distribution=floor_dist,
        )
        
        return PathResponse(success=True, summary=summary, paths=paths)
        
    except Exception as e:
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))


# ═══════════════════════════════════════════════════════════════════
if __name__ == "__main__":
    uvicorn.run("warehouse_api:app", host="127.0.0.1", port=8008, reload=False)
