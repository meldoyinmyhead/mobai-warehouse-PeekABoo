"""Forecast request/response schemas"""

from pydantic import BaseModel, Field
from typing import List, Dict, Optional


class ForecastRequest(BaseModel):
    """Request schema for forecast generation"""
    demand_data: List[Dict]
    product_data: Optional[List[Dict]] = None
    horizon_days: int = Field(default=7, ge=1, le=365)
    model_type: str = Field(default="xgboost", pattern="^(naive|exponential_smoothing|random_forest|xgboost)$")


class ForecastResponse(BaseModel):
    """Response schema for forecast"""
    success: bool
    forecast: Optional[List[Dict]] = None
    summary: Optional[Dict] = None
    model_type: Optional[str] = None
    error: Optional[str] = None
    timestamp: str
