"""Picking optimization API endpoints"""

from fastapi import APIRouter, HTTPException
import pandas as pd

from ...services import PickingService
from ..schemas.picking_request import PickingOptimizationRequest, PickingOptimizationResponse
from ...config.logging_config import get_logger

logger = get_logger("picking_routes")
router = APIRouter()


@router.post("/optimize-picking", response_model=PickingOptimizationResponse)
async def optimize_picking(request: PickingOptimizationRequest):
    """
    Optimize picking operations
    
    - **picks_data**: Pick orders to optimize
    - **locations_data**: Warehouse locations
    - **strategy**: Picking strategy ('wave', 'batch', 'zone')
    - **optimize_route**: Whether to optimize route order
    """
    logger.info("POST /optimize-picking request received")
    
    try:
        # Convert to DataFrames
        picks_df = pd.DataFrame(request.picks_data)
        locations_df = pd.DataFrame(request.locations_data)
        
        # Initialize service
        service = PickingService(strategy=request.strategy)
        
        # Optimize picking
        if request.optimize_route:
            result = service.optimize_picking_route(
                picks_df,
                locations_df,
                request.start_location
            )
        else:
            result = service.optimize_picking_list(
                picks_df,
                locations_df,
                request.strategy
            )
        
        if not result['success']:
            raise HTTPException(status_code=500, detail=result['error'])
        
        return result
        
    except Exception as e:
        logger.error(f"Error in optimize-picking endpoint: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))
