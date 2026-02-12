"""
Visualizations
Generate charts and plots for documentation
"""

import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd
from pathlib import Path

from ..config.settings import settings
from ..config.logging_config import get_logger

logger = get_logger("visualizations")

sns.set_style("whitegrid")


def plot_forecast_comparison(
    actual: pd.Series,
    predictions: dict,
    output_path: Path = None
):
    """Plot actual vs predicted forecasts"""
    logger.info("Plotting forecast comparison")
    
    plt.figure(figsize=(12, 6))
    plt.plot(actual.values, label='Actual', linewidth=2, marker='o')
    
    for model_name, pred in predictions.items():
        plt.plot(pred, label=model_name, alpha=0.7, marker='s')
    
    plt.xlabel('Time Period')
    plt.ylabel('Demand')
    plt.title('Forecast Comparison: Actual vs Models')
    plt.legend()
    plt.grid(True, alpha=0.3)
    
    if output_path:
        plt.savefig(output_path, dpi=300, bbox_inches='tight')
        logger.info(f"Chart saved to {output_path}")
    
    plt.close()


def plot_model_performance(
    comparison_df: pd.DataFrame,
    output_path: Path = None
):
    """Plot model performance metrics"""
    logger.info("Plotting model performance")
    
    fig, axes = plt.subplots(1, 3, figsize=(15, 5))
    
    metrics = ['mae', 'rmse', 'mape']
    
    for idx, metric in enumerate(metrics):
        comparison_df.plot(x='model', y=metric, kind='bar', ax=axes[idx], legend=False)
        axes[idx].set_title(f'{metric.upper()} Comparison')
        axes[idx].set_xlabel('Model')
        axes[idx].set_ylabel(metric.upper())
        axes[idx].tick_params(axis='x', rotation=45)
    
    plt.tight_layout()
    
    if output_path:
        plt.savefig(output_path, dpi=300, bbox_inches='tight')
        logger.info(f"Chart saved to {output_path}")
    
    plt.close()
