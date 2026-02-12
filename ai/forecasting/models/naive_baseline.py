"""
Naive Baseline Forecaster
Simple 7-day moving average baseline
"""

import pandas as pd
import numpy as np
from typing import Optional

from .base_forecaster import BaseForecaster
from ...config.logging_config import get_logger

logger = get_logger("naive_baseline")


class NaiveBaseline(BaseForecaster):
    """Naive baseline using moving average"""
    
    def __init__(self, window_size: int = 7):
        """
        Initialize naive baseline
        
        Args:
            window_size: Size of moving average window
        """
        super().__init__("naive_baseline")
        self.window_size = window_size
        self.historical_data = None
    
    def train(
        self,
        X_train: pd.DataFrame,
        y_train: pd.Series,
        **kwargs
    ):
        """
        Train the model (store historical data)
        
        Args:
            X_train: Training features
            y_train: Training target
        """
        logger.info(f"Training Naive Baseline with window_size={self.window_size}")
        
        # Store the historical demand data
        self.historical_data = y_train.copy()
        self.is_trained = True
        
        logger.info(f"Stored {len(self.historical_data)} historical observations")
    
    def predict(self, X_test: pd.DataFrame) -> np.ndarray:
        """
        Make predictions using moving average
        
        Args:
            X_test: Test features
            
        Returns:
            Array of predictions
        """
        if not self.is_trained:
            raise ValueError("Model must be trained before making predictions")
        
        # Use last N values for moving average
        recent_values = self.historical_data.tail(self.window_size)
        prediction = recent_values.mean()
        
        # Return same prediction for all test samples
        predictions = np.full(len(X_test), prediction)
        
        logger.debug(f"Generated {len(predictions)} predictions with mean={prediction:.2f}")
        
        return predictions
    
    def predict_per_product(
        self,
        X_test: pd.DataFrame,
        product_column: str = 'product_id'
    ) -> np.ndarray:
        """
        Make predictions per product
        
        Args:
            X_test: Test features with product IDs
            product_column: Name of product ID column
            
        Returns:
            Array of predictions
        """
        if not self.is_trained:
            raise ValueError("Model must be trained before making predictions")
        
        predictions = []
        
        # Group by product and predict
        for product_id in X_test[product_column].unique():
            product_mask = X_test[product_column] == product_id
            n_samples = product_mask.sum()
            
            # Get recent values for this product
            if isinstance(self.historical_data, pd.DataFrame):
                if product_column in self.historical_data.columns:
                    product_history = self.historical_data[
                        self.historical_data[product_column] == product_id
                    ]['demand']
                else:
                    product_history = self.historical_data
            else:
                product_history = self.historical_data
            
            if len(product_history) > 0:
                recent_values = product_history.tail(self.window_size)
                prediction = recent_values.mean()
            else:
                prediction = 0.0
            
            predictions.extend([prediction] * n_samples)
        
        return np.array(predictions)
