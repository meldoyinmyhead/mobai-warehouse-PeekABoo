"""Storage optimization request/response schemas"""

from pydantic import BaseModel
from typing import List, Dict, Optional


class StorageOptimizationRequest(BaseModel):
    """Request schema for storage optimization"""
    products_data: List[Dict]
    locations_data: List[Dict]
    demand_data: Optional[List[Dict]] = None


class StorageOptimizationResponse(BaseModel):
    """Response schema for storage optimization"""
    success: bool
    assignments: Optional[List[Dict]] = None
    metrics: Optional[Dict] = None
    error: Optional[str] = None
    timestamp: str
