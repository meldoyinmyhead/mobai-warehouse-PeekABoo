"""Forecast API endpoints"""

from fastapi import APIRouter, HTTPException
from typing import List

from ...services import ForecastingService
from ..schemas.forecast_request import ForecastRequest, ForecastResponse
from ...config.logging_config import get_logger
import pandas as pd

logger = get_logger("forecast_routes")
router = APIRouter()


@router.post("/forecast", response_model=ForecastResponse)
async def generate_forecast(request: ForecastRequest):
    """
    Generate demand forecast
    
    - **demand_data**: Historical demand data
    - **product_data**: Product attributes (optional)
    - **horizon_days**: Forecast horizon in days
    - **model_type**: Type of forecasting model
    """
    logger.info("POST /forecast request received")
    
    try:
        # Convert request data to DataFrames
        demand_df = pd.DataFrame(request.demand_data)
        product_df = pd.DataFrame(request.product_data) if request.product_data else None
        
        # Initialize service
        service = ForecastingService(model_type=request.model_type)
        
        # Generate forecast
        result = service.generate_forecast(
            demand_df,
            product_df,
            request.horizon_days
        )
        
        if not result['success']:
            raise HTTPException(status_code=500, detail=result['error'])
        
        return result
        
    except Exception as e:
        logger.error(f"Error in forecast endpoint: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/forecast/evaluate")
async def evaluate_forecast(actual_data: List[dict], predicted_data: List[dict]):
    """Evaluate forecast accuracy"""
    logger.info("POST /forecast/evaluate request received")
    
    try:
        actual_df = pd.DataFrame(actual_data)
        predicted_df = pd.DataFrame(predicted_data)
        
        service = ForecastingService()
        result = service.evaluate_forecast(actual_df, predicted_df)
        
        if not result['success']:
            raise HTTPException(status_code=500, detail=result['error'])
        
        return result
        
    except Exception as e:
        logger.error(f"Error in evaluate endpoint: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))
