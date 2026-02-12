"""
Evaluate Models
Compare performance of all forecasting models
"""

import pandas as pd
from typing import Dict, List

from ..forecasting import ForecastOrchestrator, ForecastEvaluator
from ..config.logging_config import get_logger

logger = get_logger("evaluate_models")


def evaluate_all_models(
    X_test: pd.DataFrame,
    y_test: pd.Series,
    model_types: List[str] = None
) -> pd.DataFrame:
    """
    Evaluate all trained models
    
    Args:
        X_test: Test features
        y_test: Test target
        model_types: List of models to evaluate
        
    Returns:
        DataFrame with evaluation results
    """
    if model_types is None:
        model_types = ['naive', 'exponential_smoothing', 'random_forest', 'xgboost']
    
    logger.info(f"Evaluating {len(model_types)} models")
    
    evaluator = ForecastEvaluator()
    predictions = {}
    
    for model_type in model_types:
        logger.info(f"Evaluating {model_type}")
        
        try:
            orchestrator = ForecastOrchestrator(model_type=model_type)
            orchestrator.load_model()
            
            y_pred = orchestrator.model.predict(X_test)
            predictions[model_type] = y_pred
            
        except Exception as e:
            logger.error(f"Error evaluating {model_type}: {str(e)}")
    
    # Compare models
    comparison = evaluator.compare_models(y_test.values, predictions)
    
    logger.info("Model evaluation complete")
    logger.info(f"Results:\n{comparison}")
    
    return comparison


if __name__ == "__main__":
    from ..core import DataLoader
    
    # Load data
    loader = DataLoader()
    demand_df, product_df, _ = loader.load_processed_data()
    
    # Prepare test data
    orchestrator = ForecastOrchestrator()
    X_train, X_test, y_train, y_test = orchestrator.prepare_training_data(demand_df, product_df)
    
    # Evaluate models
    results = evaluate_all_models(X_test, y_test)
    print(results)
