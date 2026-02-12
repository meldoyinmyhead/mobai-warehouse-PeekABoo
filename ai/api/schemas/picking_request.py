"""Picking optimization request/response schemas"""

from pydantic import BaseModel, Field
from typing import List, Dict, Optional


class PickingOptimizationRequest(BaseModel):
    """Request schema for picking optimization"""
    picks_data: List[Dict]
    locations_data: List[Dict]
    strategy: str = Field(default="wave", pattern="^(wave|batch|zone)$")
    optimize_route: bool = Field(default=False)
    start_location: str = Field(default="DEPOT_001")


class PickingOptimizationResponse(BaseModel):
    """Response schema for picking optimization"""
    success: bool
    picks: Optional[List[Dict]] = None
    route: Optional[List[Dict]] = None
    metrics: Optional[Dict] = None
    strategy: Optional[str] = None
    error: Optional[str] = None
    timestamp: str
