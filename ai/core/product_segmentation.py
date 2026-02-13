"""
Product Segmentation
ABC-XYZ analysis for product classification
"""

import pandas as pd
import numpy as np
from typing import Dict, Tuple

from ..config.settings import settings
from ..config.logging_config import get_logger

logger = get_logger("product_segmentation")


class ProductSegmentation:
    """Segment products using ABC-XYZ analysis"""
    
    def __init__(
        self,
        abc_thresholds: Optional[Dict[str, float]] = None,
        xyz_thresholds: Optional[Dict[str, float]] = None
    ):
        """
        Initialize ProductSegmentation
        
        Args:
            abc_thresholds: Cumulative percentage thresholds for ABC classes
            xyz_thresholds: Coefficient of variation thresholds for XYZ classes
        """
        self.abc_thresholds = abc_thresholds or settings.ABC_THRESHOLDS
        self.xyz_thresholds = xyz_thresholds or settings.XYZ_CV_THRESHOLDS
    
    def abc_analysis(self, df: pd.DataFrame, value_column: str = 'total_demand') -> pd.DataFrame:
        """
        Perform ABC analysis based on demand value
        
        Args:
            df: DataFrame with product demand data
            value_column: Column name for demand value
            
        Returns:
            DataFrame with ABC classification
        """
        logger.info("Performing ABC analysis")
        
        df = df.copy()
        
        # Sort by total demand (descending)
        df = df.sort_values(value_column, ascending=False).reset_index(drop=True)
        
        # Calculate cumulative percentage
        df['cumulative_value'] = df[value_column].cumsum()
        total_value = df[value_column].sum()
        df['cumulative_percentage'] = df['cumulative_value'] / total_value
        
        # Assign ABC class
        df['abc_class'] = 'C'
        df.loc[df['cumulative_percentage'] <= self.abc_thresholds['A'], 'abc_class'] = 'A'
        df.loc[
            (df['cumulative_percentage'] > self.abc_thresholds['A']) &
            (df['cumulative_percentage'] <= self.abc_thresholds['B']),
            'abc_class'
        ] = 'B'
        
        # Log distribution
        abc_counts = df['abc_class'].value_counts()
        logger.info(f"ABC distribution: A={abc_counts.get('A', 0)}, "
                   f"B={abc_counts.get('B', 0)}, C={abc_counts.get('C', 0)}")
        
        return df
    
    def xyz_analysis(self, df: pd.DataFrame, demand_column: str = 'demand') -> pd.DataFrame:
        """
        Perform XYZ analysis based on demand variability
        
        Args:
            df: DataFrame with product demand time series
            demand_column: Column name for demand values
            
        Returns:
            DataFrame with XYZ classification
        """
        logger.info("Performing XYZ analysis")
        
        # Calculate coefficient of variation per product
        cv_df = df.groupby('product_id')[demand_column].agg(['mean', 'std']).reset_index()
        cv_df['coefficient_of_variation'] = cv_df['std'] / cv_df['mean']
        cv_df['coefficient_of_variation'] = cv_df['coefficient_of_variation'].fillna(0)
        
        # Assign XYZ class
        cv_df['xyz_class'] = 'Z'
        cv_df.loc[cv_df['coefficient_of_variation'] <= self.xyz_thresholds['X'], 'xyz_class'] = 'X'
        cv_df.loc[
            (cv_df['coefficient_of_variation'] > self.xyz_thresholds['X']) &
            (cv_df['coefficient_of_variation'] <= self.xyz_thresholds['Y']),
            'xyz_class'
        ] = 'Y'
        
        # Log distribution
        xyz_counts = cv_df['xyz_class'].value_counts()
        logger.info(f"XYZ distribution: X={xyz_counts.get('X', 0)}, "
                   f"Y={xyz_counts.get('Y', 0)}, Z={xyz_counts.get('Z', 0)}")
        
        return cv_df[['product_id', 'coefficient_of_variation', 'xyz_class']]
    
    def segment_products(
        self,
        demand_df: pd.DataFrame,
        demand_column: str = 'demand'
    ) -> pd.DataFrame:
        """
        Perform full ABC-XYZ segmentation
        
        Args:
            demand_df: DataFrame with demand history
            demand_column: Column name for demand values
            
        Returns:
            DataFrame with ABC-XYZ segments
        """
        logger.info("Performing ABC-XYZ segmentation")
        
        # Calculate total demand per product
        product_totals = demand_df.groupby('product_id')[demand_column].sum().reset_index()
        product_totals.columns = ['product_id', 'total_demand']
        
        # ABC analysis
        abc_df = self.abc_analysis(product_totals, 'total_demand')
        
        # XYZ analysis
        xyz_df = self.xyz_analysis(demand_df, demand_column)
        
        # Merge ABC and XYZ
        segments = abc_df.merge(xyz_df, on='product_id', how='left')
        
        # Create combined segment
        segments['segment'] = segments['abc_class'] + segments['xyz_class']
        
        # Calculate velocity (demand per day)
        date_range = demand_df['date'].max() - demand_df['date'].min()
        days = date_range.days if hasattr(date_range, 'days') else 1
        segments['velocity'] = segments['total_demand'] / max(days, 1)
        
        # Priority score (higher for AX, lower for CZ)
        abc_scores = {'A': 3, 'B': 2, 'C': 1}
        xyz_scores = {'X': 3, 'Y': 2, 'Z': 1}
        segments['priority_score'] = (
            segments['abc_class'].map(abc_scores) * 
            segments['xyz_class'].map(xyz_scores)
        )
        
        logger.info(f"Segmented {len(segments)} products")
        
        return segments
    
    def get_segment_summary(self, segments: pd.DataFrame) -> pd.DataFrame:
        """
        Generate summary statistics for each segment
        
        Args:
            segments: DataFrame with product segments
            
        Returns:
            Summary DataFrame
        """
        summary = segments.groupby('segment').agg({
            'product_id': 'count',
            'total_demand': ['sum', 'mean'],
            'velocity': 'mean',
            'coefficient_of_variation': 'mean',
            'priority_score': 'mean'
        }).reset_index()
        
        summary.columns = [
            'segment', 'product_count', 'total_demand_sum',
            'total_demand_mean', 'avg_velocity', 'avg_cv', 'avg_priority'
        ]
        
        return summary.sort_values('avg_priority', ascending=False)
