"""Pydantic schemas for route-optimization endpoint."""

from __future__ import annotations
from typing import List, Optional, Tuple
from pydantic import BaseModel, Field


# ── Request ─────────────────────────────────────────────────────────

class OrderItem(BaseModel):
    """Single line in a picking order."""
    product_id: str = Field(..., examples=["31496"], description="Product ID")
    quantity: int   = Field(1, ge=1, description="Requested quantity")


class RouteOptimizationRequest(BaseModel):
    """POST body for /optimize-route."""
    items: List[OrderItem] = Field(
        ...,
        min_length=1,
        description="List of products + quantities to pick",
    )
    target_type: str = Field(
        "shelf",
        description="Ground-floor target type: 'shelf', 'exhibition', or 'all'",
    )


# ── Response (nested models) ───────────────────────────────────────

class LegDetail(BaseModel):
    """One leg of the route (walk or elevator)."""
    leg: str                          = Field(..., description="Leg label, e.g. 'walk_to_chariot', 'elevator', 'walk_to_target'")
    path: Optional[List[List[int]]]   = Field(None, description="List of [floor, row, col] waypoints (null for elevator)")
    distance: int                     = Field(..., description="Cost / distance for this leg")


class RouteResult(BaseModel):
    """Complete route result for one product."""
    product_id: str
    requested_qty: int
    available_qty: Optional[int]         = None
    candidate_slots: Optional[int]       = None

    # Location identifiers
    emplacement_id: Optional[str]        = None
    emplacement_code: Optional[str]      = None

    # Source & target
    source_floor: Optional[int]          = None
    source_row: Optional[int]            = None
    source_col: Optional[int]            = None
    source_slot_id: Optional[str]        = None

    target_slot_id: Optional[str]        = None
    target_type: Optional[str]           = None
    access_point: Optional[List[int]]    = None

    # Distances
    elevator_cost: Optional[int]         = None
    walk_to_chariot_distance: Optional[int] = None
    walk_to_target_distance: Optional[int]  = None
    total_cost: Optional[int]            = None

    # Did the route use the chariot elevator?
    used_elevator: bool                  = False
    elevator_floors_traversed: Optional[int] = None

    # Full paths as lists of [floor, row, col]
    leg1_path: Optional[List[List[int]]] = Field(None, description="Walk on source floor → chariot exit")
    leg3_path: Optional[List[List[int]]] = Field(None, description="Walk on ground floor chariot → target")

    # Chariot positions
    src_chariot: Optional[List[int]]     = None
    gf_chariot: Optional[List[int]]      = None

    # Legs breakdown
    legs: Optional[List[LegDetail]]      = None

    # Error (mutually exclusive with a successful route)
    error: Optional[str]                 = None


class RouteSummary(BaseModel):
    """Aggregate stats across all products."""
    total_items: int
    routed: int
    failed: int
    total_cost: int
    total_elevator_cost: int
    total_walk_distance: int


class RouteOptimizationResponse(BaseModel):
    """Top-level response for /optimize-route."""
    success: bool
    summary: RouteSummary
    routes: List[RouteResult]
