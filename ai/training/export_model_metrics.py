"""
Export Model Metrics
Generate comparison reports for models
"""

import pandas as pd
from pathlib import Path

from ..config.settings import settings
from ..config.logging_config import get_logger

logger = get_logger("export_model_metrics")


def export_comparison_report(
    comparison_df: pd.DataFrame,
    output_path: Path = None
) -> Path:
    """
    Export model comparison report
    
    Args:
        comparison_df: DataFrame with model comparison
        output_path: Output file path
        
    Returns:
        Path to exported file
    """
    if output_path is None:
        output_path = settings.BASE_DIR / "docs" / "model_comparison.csv"
    
    logger.info(f"Exporting comparison report to {output_path}")
    
    comparison_df.to_csv(output_path, index=False)
    
    logger.info("Report exported successfully")
    
    return output_path


def generate_markdown_report(comparison_df: pd.DataFrame, output_path: Path = None) -> Path:
    """Generate markdown report"""
    if output_path is None:
        output_path = settings.BASE_DIR / "docs" / "model_comparison.md"
    
    logger.info(f"Generating markdown report to {output_path}")
    
    with open(output_path, 'w') as f:
        f.write("# Forecasting Model Comparison\n\n")
        f.write(comparison_df.to_markdown(index=False))
        f.write("\n\n")
        
        # Add best model
        best_model = comparison_df.iloc[0]['model']
        best_mae = comparison_df.iloc[0]['mae']
        f.write(f"**Best Model:** {best_model} (MAE: {best_mae:.4f})\n")
    
    logger.info("Markdown report generated")
    
    return output_path
