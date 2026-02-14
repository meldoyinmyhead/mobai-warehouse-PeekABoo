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


@router.get("/forecast/latest")
async def get_latest_forecast():
    """
    Get the latest pre-computed forecast from the notebook output.
    
    Returns forecasts for all products with:
    - id_produit: Product ID
    - date: Forecast date
    - segment: Product segment (A_HIGH_FREQ_HIGH_VOL, B, C, D)
    - quantite_demande: Actual demand (for validation)
    - forecast: Calibrated forecast value
    - method: Forecasting method used
    """
    logger.info("GET /forecast/latest request received")
    
    try:
        import os
        
        # Path to the pre-computed forecast CSV
        base_path = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(__file__))))
        csv_path = os.path.join(base_path, "notebooks", "data", "outputs", "final_production_forecasts_CALIBRATED.csv")
        
        if not os.path.exists(csv_path):
            raise HTTPException(status_code=404, detail="Forecast file not found. Run the forecasting notebook first.")
        
        df = pd.read_csv(csv_path)
        
        # Calculate summary statistics
        summary = {
            "total_products": int(df['id_produit'].nunique()),
            "total_forecast": float(df['forecast'].sum()),
            "avg_forecast": float(df['forecast'].mean()),
            "forecast_date": df['date'].iloc[0] if len(df) > 0 else None,
            "segments": df['segment'].value_counts().to_dict(),
            "methods_used": df['method'].unique().tolist()
        }
        
        return {
            "success": True,
            "forecast": df.to_dict(orient='records'),
            "summary": summary,
            "source": "pre-computed (calibrated)",
            "total_records": len(df)
        }
        
    except FileNotFoundError:
        raise HTTPException(status_code=404, detail="Forecast file not found")
    except Exception as e:
        logger.error(f"Error in get_latest_forecast: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/forecast/product/{product_id}")
async def get_product_forecast(product_id: str):
    """
    Get forecast for a specific product.
    
    - **product_id**: The product ID to get forecast for
    """
    logger.info(f"GET /forecast/product/{product_id} request received")
    
    try:
        import os
        
        base_path = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(__file__))))
        csv_path = os.path.join(base_path, "notebooks", "data", "outputs", "final_production_forecasts_CALIBRATED.csv")
        
        if not os.path.exists(csv_path):
            raise HTTPException(status_code=404, detail="Forecast file not found")
        
        df = pd.read_csv(csv_path)
        
        # Filter for specific product
        product_df = df[df['id_produit'].astype(str) == str(product_id)]
        
        if len(product_df) == 0:
            raise HTTPException(status_code=404, detail=f"No forecast found for product {product_id}")
        
        return {
            "success": True,
            "product_id": product_id,
            "forecast": product_df.to_dict(orient='records'),
            "segment": product_df['segment'].iloc[0],
            "method": product_df['method'].iloc[0],
            "total_forecast": float(product_df['forecast'].sum())
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in get_product_forecast: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/forecast/summary")
async def get_forecast_summary():
    """
    Get a summary of the latest forecast without full data.
    Useful for dashboard overview.
    """
    logger.info("GET /forecast/summary request received")
    
    try:
        import os
        
        base_path = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(__file__))))
        csv_path = os.path.join(base_path, "notebooks", "data", "outputs", "final_production_forecasts_CALIBRATED.csv")
        
        if not os.path.exists(csv_path):
            raise HTTPException(status_code=404, detail="Forecast file not found")
        
        df = pd.read_csv(csv_path)
        
        # Group by segment for summary
        segment_summary = df.groupby('segment').agg({
            'id_produit': 'nunique',
            'forecast': ['sum', 'mean'],
            'quantite_demande': 'sum'
        }).reset_index()
        
        segment_summary.columns = ['segment', 'product_count', 'total_forecast', 'avg_forecast', 'total_actual']
        
        return {
            "success": True,
            "forecast_date": df['date'].iloc[0] if len(df) > 0 else None,
            "total_products": int(df['id_produit'].nunique()),
            "total_forecast": float(df['forecast'].sum()),
            "total_actual": float(df['quantite_demande'].sum()),
            "overall_accuracy": round(100 * (1 - abs(df['forecast'].sum() - df['quantite_demande'].sum()) / df['quantite_demande'].sum()), 2),
            "by_segment": segment_summary.to_dict(orient='records'),
            "methods_used": df['method'].unique().tolist()
        }
        
    except Exception as e:
        logger.error(f"Error in get_forecast_summary: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))
