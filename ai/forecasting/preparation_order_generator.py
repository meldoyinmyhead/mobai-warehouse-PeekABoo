"""
Preparation Order Generator
Generate preparation orders based on demand forecast
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from typing import Dict, Optional

from ..config.settings import settings
from ..config.logging_config import get_logger

logger = get_logger("preparation_order_generator")


class PreparationOrderGenerator:
    """Generate preparation orders from demand forecasts"""
    
    def __init__(self, safety_stock_days: int = 2):
        """
        Initialize PreparationOrderGenerator
        
        Args:
            safety_stock_days: Number of days of safety stock
        """
        self.safety_stock_days = safety_stock_days
    
    def calculate_preparation_quantity(
        self,
        forecast_demand: float,
        current_stock: float,
        safety_stock: float
    ) -> float:
        """
        Calculate preparation quantity needed
        
        Args:
            forecast_demand: Forecasted demand
            current_stock: Current stock level
            safety_stock: Safety stock level
            
        Returns:
            Preparation quantity
        """
        required_stock = forecast_demand + safety_stock
        preparation_qty = max(0, required_stock - current_stock)
        
        return preparation_qty
    
    def generate_preparation_orders(
        self,
        forecast_df: pd.DataFrame,
        inventory_df: pd.DataFrame,
        product_df: Optional[pd.DataFrame] = None
    ) -> pd.DataFrame:
        """
        Generate preparation orders from forecast
        
        Args:
            forecast_df: Forecast DataFrame with columns [product_id, date, forecast]
            inventory_df: Current inventory DataFrame with columns [product_id, current_stock]
            product_df: Product attributes DataFrame
            
        Returns:
            DataFrame with preparation orders
        """
        logger.info("Generating preparation orders")
        
        # Merge forecast with inventory
        orders_df = forecast_df.merge(
            inventory_df[['product_id', 'current_stock']],
            on='product_id',
            how='left'
        )
        
        # Fill missing current_stock with 0
        orders_df['current_stock'] = orders_df['current_stock'].fillna(0)
        
        # Calculate safety stock (based on forecast)
        orders_df['safety_stock'] = orders_df['forecast'] * self.safety_stock_days
        
        # Calculate preparation quantity
        orders_df['preparation_qty'] = orders_df.apply(
            lambda row: self.calculate_preparation_quantity(
                row['forecast'],
                row['current_stock'],
                row['safety_stock']
            ),
            axis=1
        )
        
        # Filter out zero quantities
        orders_df = orders_df[orders_df['preparation_qty'] > 0].copy()
        
        # Add order metadata
        orders_df['order_date'] = datetime.now()
        orders_df['order_id'] = [f"PREP_{i+1:06d}" for i in range(len(orders_df))]
        orders_df['order_type'] = 'PREPARATION'
        orders_df['status'] = 'PENDING'
        
        # Merge with product attributes if provided
        if product_df is not None:
            orders_df = orders_df.merge(
                product_df,
                on='product_id',
                how='left'
            )
        
        # Calculate priority (higher for higher forecast)
        orders_df['priority'] = orders_df['forecast'].rank(ascending=False, method='dense').astype(int)
        
        # Select and order columns
        output_cols = [
            'order_id', 'product_id', 'date', 'preparation_qty',
            'forecast', 'current_stock', 'safety_stock',
            'priority', 'order_date', 'order_type', 'status'
        ]
        
        # Add product columns if available
        if product_df is not None:
            product_cols = [col for col in product_df.columns if col != 'product_id']
            output_cols = output_cols[:2] + product_cols + output_cols[2:]
        
        # Filter to available columns
        available_cols = [col for col in output_cols if col in orders_df.columns]
        orders_df = orders_df[available_cols]
        
        # Sort by priority
        orders_df = orders_df.sort_values('priority')
        
        logger.info(f"Generated {len(orders_df)} preparation orders")
        
        return orders_df
    
    def aggregate_orders_by_date(
        self,
        orders_df: pd.DataFrame
    ) -> pd.DataFrame:
        """
        Aggregate orders by date
        
        Args:
            orders_df: Preparation orders DataFrame
            
        Returns:
            Aggregated DataFrame
        """
        aggregated = orders_df.groupby('date').agg({
            'order_id': 'count',
            'preparation_qty': 'sum',
            'forecast': 'sum'
        }).reset_index()
        
        aggregated.columns = ['date', 'order_count', 'total_qty', 'total_forecast']
        
        return aggregated
    
    def export_orders(
        self,
        orders_df: pd.DataFrame,
        filepath: str,
        format: str = 'csv'
    ):
        """
        Export preparation orders to file
        
        Args:
            orders_df: Preparation orders DataFrame
            filepath: Output file path
            format: Output format ('csv' or 'excel')
        """
        logger.info(f"Exporting orders to {filepath}")
        
        if format == 'csv':
            orders_df.to_csv(filepath, index=False)
        elif format == 'excel':
            orders_df.to_excel(filepath, index=False)
        else:
            raise ValueError(f"Unsupported format: {format}")
        
        logger.info(f"Exported {len(orders_df)} orders to {filepath}")
