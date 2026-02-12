"""
Evaluation Metrics
Comprehensive metrics for AI solution evaluation
"""

import pandas as pd
import numpy as np
from typing import Dict

from ..config.logging_config import get_logger

logger = get_logger("metrics")


def calculate_all_metrics(
    y_true: np.ndarray,
    y_pred: np.ndarray,
    travel_distances: Dict = None
) -> Dict:
    """
    Calculate all evaluation metrics
    
    Args:
        y_true: True values
        y_pred: Predicted values
        travel_distances: Dictionary with travel distance metrics
        
    Returns:
        Dictionary with all metrics
    """
    from ..forecasting import ForecastEvaluator
    
    evaluator = ForecastEvaluator()
    metrics = evaluator.evaluate(y_true, y_pred)
    
    # Add travel distance metrics if provided
    if travel_distances:
        metrics.update(travel_distances)
    
    return metrics


def calculate_improvement_percentage(baseline: float, proposed: float) -> float:
    """Calculate percentage improvement"""
    if baseline == 0:
        return 0.0
    return ((baseline - proposed) / baseline) * 100
