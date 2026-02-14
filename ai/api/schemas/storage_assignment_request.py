"""Pydantic schemas for storage-assignment endpoint."""

from __future__ import annotations
from typing import List, Optional
from pydantic import BaseModel, Field


# ── Request ─────────────────────────────────────────────────────────

class StorageItem(BaseModel):
    """Single line in a storage order."""
    product_id: str = Field(..., examples=["31851"], description="Product ID")
    quantity: int   = Field(1, ge=1, description="Number of units to store")


class StorageAssignmentRequest(BaseModel):
    """POST body for /assign-storage."""
    items: List[StorageItem] = Field(
        ...,
        min_length=1,
        description="List of products + quantities to assign to storage slots",
    )
    mode: str = Field(
        "greedy",
        description="Assignment mode: 'greedy' (sequential best-slot) or 'milp' (batch linear programming)",
    )
    slot_capacity_cap: Optional[float] = Field(
        None,
        ge=0.001,
        description="Optional: cap each slot capacity to this value (m³) for demo/spread purposes. "
                    "Leave null to use real warehouse capacity.",
    )


# ── Response (nested models) ───────────────────────────────────────

class JourneyDetail(BaseModel):
    """Step-by-step journey from ground floor to assigned slot."""
    start: str                               = Field("Ground Floor (0) — Receiving zone")
    elevator_from: int                       = Field(0, description="Elevator departure floor")
    elevator_to: int                         = Field(..., description="Elevator arrival floor")
    elevator_distance: int                   = Field(..., description="Elevator travel distance (m)")
    walk_from: str                           = Field(..., description="Walk start (chariot exit)")
    walk_to: str                             = Field(..., description="Walk end (assigned slot)")
    walk_distance: int                       = Field(..., description="Walk distance on floor (m)")
    total_distance: int                      = Field(..., description="Elevator + walk (m)")
    walk_path: Optional[List[List[int]]]     = Field(None, description="Waypoints (row, col) on the floor")


class AssignmentResult(BaseModel):
    """Complete assignment result for one product unit."""
    product_id: str
    unit: int                                = Field(..., description="Unit number for this product (1-based)")
    total_units: int                         = Field(..., description="Total units requested for this product")

    # Product attributes
    product_name: Optional[str]              = None
    category: Optional[str]                  = None
    abc_class: Optional[str]                 = None
    product_volume_m3: Optional[float]       = None
    product_weight_kg: Optional[float]       = None
    demand_frequency: Optional[float]        = None
    reception_frequency: Optional[float]     = None

    # Assigned slot
    emplacement_code: Optional[str]          = None
    emplacement_id: Optional[str]            = None
    floor: Optional[int]                     = None
    row: Optional[int]                       = None
    col: Optional[int]                       = None

    # Cost & distances
    placement_cost: Optional[float]          = None
    elevator_cost: Optional[int]             = None
    walk_distance: Optional[int]             = None
    total_distance: Optional[int]            = None
    remaining_capacity_m3: Optional[float]   = None

    # Elevator details
    used_elevator: bool                      = False
    elevator_floors_traversed: Optional[int] = None

    # Journey description
    journey: Optional[JourneyDetail]         = None

    # Full path as [[row, col], ...] on the assigned floor
    path: Optional[List[List[int]]]          = None

    # Error (if assignment failed for this product)
    error: Optional[str]                     = None


class AssignmentSummary(BaseModel):
    """Aggregate stats across all assignments."""
    total_items: int                          = Field(..., description="Total order lines")
    total_units: int                          = Field(..., description="Total individual units requested")
    assigned: int                             = Field(..., description="Units successfully assigned")
    skipped: int                              = Field(..., description="Units that could not be assigned")
    total_placement_cost: float               = Field(..., description="Sum of placement costs")
    total_travel_distance: int                = Field(..., description="Sum of total distances (m)")
    total_elevator_distance: int              = Field(..., description="Sum of elevator distances (m)")
    total_walk_distance: int                  = Field(..., description="Sum of walk distances (m)")
    unique_slots_used: int                    = Field(..., description="Number of distinct slots used")
    floor_distribution: dict                  = Field(..., description="Count of assignments per floor")
    mode: str                                 = Field(..., description="Assignment mode used")


class StorageAssignmentResponse(BaseModel):
    """Top-level response for /assign-storage."""
    success: bool
    summary: AssignmentSummary
    assignments: List[AssignmentResult]
    skipped: List[dict]                       = Field(default_factory=list, description="Products that failed")
