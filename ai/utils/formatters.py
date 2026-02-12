"""Output formatting utilities"""

import pandas as pd
from typing import Dict, Any
import json


def format_output(data: pd.DataFrame, format_type: str = "json") -> Any:
    """
    Format DataFrame output
    
    Args:
        data: DataFrame to format
        format_type: Output format ('json', 'dict', 'csv')
        
    Returns:
        Formatted data
    """
    if format_type == "json":
        return data.to_json(orient='records')
    elif format_type == "dict":
        return data.to_dict(orient='records')
    elif format_type == "csv":
        return data.to_csv(index=False)
    else:
        return data


def format_metrics(metrics: Dict[str, float], precision: int = 2) -> Dict[str, str]:
    """
    Format metrics for display
    
    Args:
        metrics: Dictionary of metrics
        precision: Decimal precision
        
    Returns:
        Formatted metrics
    """
    formatted = {}
    for key, value in metrics.items():
        if isinstance(value, float):
            formatted[key] = f"{value:.{precision}f}"
        else:
            formatted[key] = str(value)
    
    return formatted


def format_percentage(value: float, precision: int = 1) -> str:
    """Format value as percentage"""
    return f"{value * 100:.{precision}f}%"


def format_currency(value: float, currency: str = "$", precision: int = 2) -> str:
    """Format value as currency"""
    return f"{currency}{value:,.{precision}f}"
