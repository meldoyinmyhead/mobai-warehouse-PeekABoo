"""Storage optimization API endpoints"""

from fastapi import APIRouter, HTTPException
import pandas as pd

from ...services import StorageService
from ..schemas.storage_request import StorageOptimizationRequest, StorageOptimizationResponse
from ...config.logging_config import get_logger

logger = get_logger("storage_routes")
router = APIRouter()


@router.post("/optimize-storage", response_model=StorageOptimizationResponse)
async def optimize_storage(request: StorageOptimizationRequest):
    """
    Optimize storage locations for products
    
    - **products_data**: Product attributes
    - **locations_data**: Available warehouse locations
    - **demand_data**: Historical demand (optional)
    """
    logger.info("POST /optimize-storage request received")
    
    try:
        # Convert to DataFrames
        products_df = pd.DataFrame(request.products_data)
        locations_df = pd.DataFrame(request.locations_data)
        demand_df = pd.DataFrame(request.demand_data) if request.demand_data else None
        
        # Initialize service
        service = StorageService()
        
        # Optimize storage
        result = service.optimize_storage_layout(
            products_df,
            locations_df,
            demand_df
        )
        
        if not result['success']:
            raise HTTPException(status_code=500, detail=result['error'])
        
        return result
        
    except Exception as e:
        logger.error(f"Error in optimize-storage endpoint: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))
