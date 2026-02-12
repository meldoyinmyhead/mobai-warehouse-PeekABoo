"""
Exponential Smoothing Forecaster
Holt-Winters exponential smoothing for time series
"""

import pandas as pd
import numpy as np
from statsmodels.tsa.holtwinters import ExponentialSmoothing as HoltWinters

from .base_forecaster import BaseForecaster
from ...config.logging_config import get_logger

logger = get_logger("exponential_smoothing")


class ExponentialSmoothing(BaseForecaster):
    """Holt-Winters exponential smoothing forecaster"""
    
    def __init__(
        self,
        seasonal_periods: int = 7,
        trend: str = 'add',
        seasonal: str = 'add'
    ):
        """
        Initialize exponential smoothing model
        
        Args:
            seasonal_periods: Number of periods in a season
            trend: Type of trend component ('add', 'mul', or None)
            seasonal: Type of seasonal component ('add', 'mul', or None)
        """
        super().__init__("exponential_smoothing")
        self.seasonal_periods = seasonal_periods
        self.trend = trend
        self.seasonal = seasonal
    
    def train(
        self,
        X_train: pd.DataFrame,
        y_train: pd.Series,
        **kwargs
    ):
        """
        Train the exponential smoothing model
        
        Args:
            X_train: Training features
            y_train: Training target
        """
        logger.info(f"Training Exponential Smoothing (trend={self.trend}, seasonal={self.seasonal})")
        
        try:
            # Fit Holt-Winters model
            self.model = HoltWinters(
                y_train,
                seasonal_periods=self.seasonal_periods,
                trend=self.trend,
                seasonal=self.seasonal
            ).fit()
            
            self.is_trained = True
            logger.info("Exponential Smoothing model trained successfully")
            
        except Exception as e:
            logger.error(f"Error training Exponential Smoothing: {str(e)}")
            raise
    
    def predict(self, X_test: pd.DataFrame) -> np.ndarray:
        """
        Make predictions
        
        Args:
            X_test: Test features
            
        Returns:
            Array of predictions
        """
        if not self.is_trained:
            raise ValueError("Model must be trained before making predictions")
        
        try:
            # Forecast for the test period
            n_steps = len(X_test)
            predictions = self.model.forecast(steps=n_steps)
            
            # Ensure non-negative predictions
            predictions = np.maximum(predictions, 0)
            
            logger.debug(f"Generated {len(predictions)} predictions")
            
            return predictions
            
        except Exception as e:
            logger.error(f"Error making predictions: {str(e)}")
            raise
