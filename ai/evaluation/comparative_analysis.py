"""
Comparative Analysis
Compare naive approach vs proposed AI solution
"""

import pandas as pd
from typing import Dict

from ..config.logging_config import get_logger

logger = get_logger("comparative_analysis")


def compare_naive_vs_proposed(
    naive_metrics: Dict,
    proposed_metrics: Dict
) -> pd.DataFrame:
    """
    Compare naive baseline with proposed solution
    
    Args:
        naive_metrics: Metrics from naive approach
        proposed_metrics: Metrics from AI solution
        
    Returns:
        DataFrame with comparison
    """
    logger.info("Comparing naive vs proposed approaches")
    
    comparison = []
    
    for metric_name in naive_metrics.keys():
        if metric_name in proposed_metrics:
            naive_value = naive_metrics[metric_name]
            proposed_value = proposed_metrics[metric_name]
            
            # Calculate improvement
            if isinstance(naive_value, (int, float)) and isinstance(proposed_value, (int, float)):
                improvement = ((naive_value - proposed_value) / naive_value * 100) if naive_value != 0 else 0
                
                comparison.append({
                    'metric': metric_name,
                    'naive': naive_value,
                    'proposed': proposed_value,
                    'improvement_%': improvement
                })
    
    comparison_df = pd.DataFrame(comparison)
    
    logger.info("Comparison complete")
    logger.info(f"\n{comparison_df}")
    
    return comparison_df
