"""
Train Forecast Models
Script to train all forecasting models
"""

import pandas as pd
from pathlib import Path
from typing import Dict, List

from ..forecasting import ForecastOrchestrator
from ..core import DataLoader
from ..config.settings import settings
from ..config.logging_config import get_logger

logger = get_logger("train_forecast_models")


def train_all_models(
    demand_data: pd.DataFrame,
    product_data: pd.DataFrame = None,
    model_types: List[str] = None
) -> Dict:
    """
    Train all forecasting models
    
    Args:
        demand_data: Historical demand data
        product_data: Product attributes
        model_types: List of model types to train
        
    Returns:
        Dictionary with training results
    """
    if model_types is None:
        model_types = ['naive', 'exponential_smoothing', 'random_forest', 'xgboost']
    
    logger.info(f"Training {len(model_types)} models")
    
    results = {}
    
    for model_type in model_types:
        logger.info(f"Training {model_type} model")
        
        try:
            orchestrator = ForecastOrchestrator(model_type=model_type)
            model = orchestrator.train_model(demand_data, product_data)
            
            # Save model
            model_path = settings.MODELS_DIR / f"{model_type}_model.pkl"
            orchestrator.save_model(model_path)
            
            results[model_type] = {
                'success': True,
                'model_path': str(model_path)
            }
            
            logger.info(f"{model_type} model trained successfully")
            
        except Exception as e:
            logger.error(f"Error training {model_type}: {str(e)}")
            results[model_type] = {
                'success': False,
                'error': str(e)
            }
    
    return results


if __name__ == "__main__":
    # Load data
    loader = DataLoader()
    demand_df, product_df, _ = loader.load_processed_data()
    
    # Train models
    results = train_all_models(demand_df, product_df)
    
    # Print summary
    for model_type, result in results.items():
        status = "✓" if result['success'] else "✗"
        print(f"{status} {model_type}: {result}")
