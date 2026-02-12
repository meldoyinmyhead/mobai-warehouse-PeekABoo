"""
Forecast Evaluator
Evaluation metrics for forecasting models
"""

import pandas as pd
import numpy as np
from typing import Dict, List
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score

from ..config.logging_config import get_logger

logger = get_logger("evaluator")


class ForecastEvaluator:
    """Evaluate forecasting model performance"""
    
    @staticmethod
    def calculate_mae(y_true: np.ndarray, y_pred: np.ndarray) -> float:
        """Calculate Mean Absolute Error"""
        return mean_absolute_error(y_true, y_pred)
    
    @staticmethod
    def calculate_rmse(y_true: np.ndarray, y_pred: np.ndarray) -> float:
        """Calculate Root Mean Squared Error"""
        return np.sqrt(mean_squared_error(y_true, y_pred))
    
    @staticmethod
    def calculate_mape(y_true: np.ndarray, y_pred: np.ndarray) -> float:
        """
        Calculate Mean Absolute Percentage Error
        
        Args:
            y_true: True values
            y_pred: Predicted values
            
        Returns:
            MAPE value (0-100 scale)
        """
        # Avoid division by zero
        mask = y_true != 0
        if not np.any(mask):
            return 0.0
        
        mape = np.mean(np.abs((y_true[mask] - y_pred[mask]) / y_true[mask])) * 100
        return mape
    
    @staticmethod
    def calculate_smape(y_true: np.ndarray, y_pred: np.ndarray) -> float:
        """
        Calculate Symmetric Mean Absolute Percentage Error
        
        Args:
            y_true: True values
            y_pred: Predicted values
            
        Returns:
            SMAPE value (0-100 scale)
        """
        denominator = (np.abs(y_true) + np.abs(y_pred)) / 2
        mask = denominator != 0
        
        if not np.any(mask):
            return 0.0
        
        smape = np.mean(np.abs(y_true[mask] - y_pred[mask]) / denominator[mask]) * 100
        return smape
    
    @staticmethod
    def calculate_r2(y_true: np.ndarray, y_pred: np.ndarray) -> float:
        """Calculate R² Score"""
        return r2_score(y_true, y_pred)
    
    @classmethod
    def evaluate(
        cls,
        y_true: np.ndarray,
        y_pred: np.ndarray,
        metrics: List[str] = None
    ) -> Dict[str, float]:
        """
        Evaluate predictions with multiple metrics
        
        Args:
            y_true: True values
            y_pred: Predicted values
            metrics: List of metrics to calculate (default: all)
            
        Returns:
            Dictionary of metric results
        """
        if metrics is None:
            metrics = ['mae', 'rmse', 'mape', 'smape', 'r2']
        
        results = {}
        
        if 'mae' in metrics:
            results['mae'] = cls.calculate_mae(y_true, y_pred)
        
        if 'rmse' in metrics:
            results['rmse'] = cls.calculate_rmse(y_true, y_pred)
        
        if 'mape' in metrics:
            results['mape'] = cls.calculate_mape(y_true, y_pred)
        
        if 'smape' in metrics:
            results['smape'] = cls.calculate_smape(y_true, y_pred)
        
        if 'r2' in metrics:
            results['r2'] = cls.calculate_r2(y_true, y_pred)
        
        logger.info(f"Evaluation metrics: {results}")
        
        return results
    
    @classmethod
    def evaluate_by_product(
        cls,
        df: pd.DataFrame,
        y_true_col: str = 'actual',
        y_pred_col: str = 'predicted',
        product_col: str = 'product_id'
    ) -> pd.DataFrame:
        """
        Evaluate predictions per product
        
        Args:
            df: DataFrame with actual and predicted values
            y_true_col: Column name for actual values
            y_pred_col: Column name for predicted values
            product_col: Column name for product IDs
            
        Returns:
            DataFrame with per-product metrics
        """
        logger.info("Evaluating per product")
        
        results = []
        
        for product_id in df[product_col].unique():
            product_df = df[df[product_col] == product_id]
            y_true = product_df[y_true_col].values
            y_pred = product_df[y_pred_col].values
            
            metrics = cls.evaluate(y_true, y_pred)
            metrics['product_id'] = product_id
            metrics['n_samples'] = len(product_df)
            
            results.append(metrics)
        
        results_df = pd.DataFrame(results)
        logger.info(f"Evaluated {len(results_df)} products")
        
        return results_df
    
    @classmethod
    def compare_models(
        cls,
        y_true: np.ndarray,
        predictions_dict: Dict[str, np.ndarray]
    ) -> pd.DataFrame:
        """
        Compare multiple models
        
        Args:
            y_true: True values
            predictions_dict: Dictionary of {model_name: predictions}
            
        Returns:
            DataFrame with comparison results
        """
        logger.info(f"Comparing {len(predictions_dict)} models")
        
        results = []
        
        for model_name, y_pred in predictions_dict.items():
            metrics = cls.evaluate(y_true, y_pred)
            metrics['model'] = model_name
            results.append(metrics)
        
        comparison_df = pd.DataFrame(results)
        comparison_df = comparison_df[['model', 'mae', 'rmse', 'mape', 'smape', 'r2']]
        
        # Sort by MAE (lower is better)
        comparison_df = comparison_df.sort_values('mae')
        
        logger.info("Model comparison complete")
        
        return comparison_df
