"""
Forecasting Service
High-level API for demand forecasting operations
"""

import pandas as pd
from typing import Dict, Optional, List
from datetime import datetime

from ..forecasting import ForecastOrchestrator, ForecastEvaluator, PreparationOrderGenerator
from ..core import DataLoader
from ..config.settings import settings
from ..config.logging_config import get_logger

logger = get_logger("forecasting_service")


class ForecastingService:
    """Service layer for forecasting operations"""
    
    def __init__(self, model_type: str = None):
        """
        Initialize ForecastingService
        
        Args:
            model_type: Type of forecasting model
        """
        self.orchestrator = ForecastOrchestrator(model_type)
        self.evaluator = ForecastEvaluator()
        self.order_generator = PreparationOrderGenerator()
        self.data_loader = DataLoader()
    
    def generate_forecast(
        self,
        demand_data: pd.DataFrame,
        product_data: Optional[pd.DataFrame] = None,
        horizon_days: int = None
    ) -> Dict:
        """
        Generate demand forecast
        
        Args:
            demand_data: Historical demand DataFrame
            product_data: Product attributes DataFrame
            horizon_days: Forecast horizon in days
            
        Returns:
            Dictionary with forecast results
        """
        logger.info("Generating forecast")
        
        try:
            # Train model if needed
            if self.orchestrator.model is None or not self.orchestrator.model.is_trained:
                logger.info("Training model first")
                self.orchestrator.train_model(demand_data, product_data)
            
            # Generate forecast
            forecast_df = self.orchestrator.forecast(
                demand_data,
                product_data,
                horizon_days
            )
            
            # Calculate summary statistics
            summary = {
                'total_forecast': float(forecast_df['forecast'].sum()),
                'avg_daily_forecast': float(forecast_df['forecast'].mean()),
                'max_daily_forecast': float(forecast_df['forecast'].max()),
                'min_daily_forecast': float(forecast_df['forecast'].min()),
                'forecast_days': len(forecast_df)
            }
            
            return {
                'success': True,
                'forecast': forecast_df.to_dict(orient='records'),
                'summary': summary,
                'model_type': self.orchestrator.model_type,
                'timestamp': datetime.now().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error generating forecast: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'timestamp': datetime.now().isoformat()
            }
    
    def evaluate_forecast(
        self,
        actual: pd.DataFrame,
        predicted: pd.DataFrame
    ) -> Dict:
        """
        Evaluate forecast accuracy
        
        Args:
            actual: DataFrame with actual demand
            predicted: DataFrame with predicted demand
            
        Returns:
            Dictionary with evaluation metrics
        """
        logger.info("Evaluating forecast")
        
        try:
            y_true = actual['demand'].values
            y_pred = predicted['forecast'].values
            
            metrics = self.evaluator.evaluate(y_true, y_pred)
            
            return {
                'success': True,
                'metrics': metrics,
                'timestamp': datetime.now().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error evaluating forecast: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'timestamp': datetime.now().isoformat()
            }
    
    def generate_preparation_orders(
        self,
        forecast_df: pd.DataFrame,
        inventory_df: pd.DataFrame,
        product_df: Optional[pd.DataFrame] = None
    ) -> Dict:
        """
        Generate preparation orders from forecast
        
        Args:
            forecast_df: Forecast DataFrame
            inventory_df: Current inventory DataFrame
            product_df: Product attributes DataFrame
            
        Returns:
            Dictionary with preparation orders
        """
        logger.info("Generating preparation orders")
        
        try:
            orders_df = self.order_generator.generate_preparation_orders(
                forecast_df,
                inventory_df,
                product_df
            )
            
            summary = {
                'total_orders': len(orders_df),
                'total_quantity': float(orders_df['preparation_qty'].sum()),
                'avg_quantity': float(orders_df['preparation_qty'].mean()),
                'priority_distribution': orders_df['priority'].value_counts().to_dict()
            }
            
            return {
                'success': True,
                'orders': orders_df.to_dict(orient='records'),
                'summary': summary,
                'timestamp': datetime.now().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error generating preparation orders: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'timestamp': datetime.now().isoformat()
            }
    
    def train_and_save_model(
        self,
        demand_data: pd.DataFrame,
        product_data: Optional[pd.DataFrame] = None,
        model_path: Optional[str] = None
    ) -> Dict:
        """
        Train model and save to disk
        
        Args:
            demand_data: Historical demand data
            product_data: Product attributes
            model_path: Path to save model
            
        Returns:
            Dictionary with training results
        """
        logger.info("Training and saving model")
        
        try:
            # Train model
            model = self.orchestrator.train_model(demand_data, product_data)
            
            # Save model
            if model_path:
                from pathlib import Path
                self.orchestrator.save_model(Path(model_path))
            else:
                self.orchestrator.save_model()
            
            return {
                'success': True,
                'model_type': self.orchestrator.model_type,
                'trained': True,
                'timestamp': datetime.now().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error training model: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'timestamp': datetime.now().isoformat()
            }
