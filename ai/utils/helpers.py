"""Helper utility functions"""

import json
import yaml
import pickle
from pathlib import Path
from typing import Any, Dict
import pandas as pd

from ..config.logging_config import get_logger

logger = get_logger("helpers")


def load_config(filepath: Path, format: str = "auto") -> Dict:
    """
    Load configuration from file
    
    Args:
        filepath: Path to config file
        format: Format ('json', 'yaml', or 'auto')
        
    Returns:
        Configuration dictionary
    """
    if format == "auto":
        format = filepath.suffix[1:]  # Remove dot
    
    with open(filepath, 'r') as f:
        if format == 'json':
            return json.load(f)
        elif format in ['yaml', 'yml']:
            return yaml.safe_load(f)
        else:
            raise ValueError(f"Unsupported config format: {format}")


def save_results(data: Any, filepath: Path, format: str = "auto"):
    """
    Save results to file
    
    Args:
        data: Data to save
        filepath: Output file path
        format: Format ('json', 'csv', 'parquet', 'pickle', or 'auto')
    """
    if format == "auto":
        format = filepath.suffix[1:]
    
    logger.info(f"Saving results to {filepath}")
    
    if format == 'json':
        if isinstance(data, pd.DataFrame):
            data.to_json(filepath, orient='records', indent=2)
        else:
            with open(filepath, 'w') as f:
                json.dump(data, f, indent=2)
    
    elif format == 'csv':
        if isinstance(data, pd.DataFrame):
            data.to_csv(filepath, index=False)
        else:
            raise ValueError("CSV format requires DataFrame")
    
    elif format == 'parquet':
        if isinstance(data, pd.DataFrame):
            data.to_parquet(filepath, index=False)
        else:
            raise ValueError("Parquet format requires DataFrame")
    
    elif format in ['pickle', 'pkl']:
        with open(filepath, 'wb') as f:
            pickle.dump(data, f)
    
    else:
        raise ValueError(f"Unsupported format: {format}")
    
    logger.info(f"Results saved successfully")


def ensure_dir(directory: Path):
    """Ensure directory exists"""
    directory.mkdir(parents=True, exist_ok=True)
