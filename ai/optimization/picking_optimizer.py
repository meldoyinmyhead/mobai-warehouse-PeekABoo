"""
Picking Optimizer
Optimal picking location assignment and wave planning
"""

import pandas as pd
import numpy as np
from typing import Dict, List, Optional
from datetime import datetime

from .scoring_functions import LocationScorer
from ..core import DistanceCalculator
from ..config.settings import settings
from ..config.logging_config import get_logger

logger = get_logger("picking_optimizer")


class PickingOptimizer:
    """Optimize picking operations"""
    
    def __init__(self, strategy: str = None, batch_size: int = None):
        """
        Initialize PickingOptimizer
        
        Args:
            strategy: Picking strategy ('wave', 'batch', 'zone')
            batch_size: Maximum number of picks per batch
        """
        self.strategy = strategy or settings.PICKING_STRATEGY
        self.batch_size = batch_size or settings.PICKING_BATCH_SIZE
        self.distance_calculator = DistanceCalculator()
    
    def create_picking_waves(
        self,
        orders_df: pd.DataFrame,
        wave_size: int = None
    ) -> pd.DataFrame:
        """
        Group orders into picking waves
        
        Args:
            orders_df: DataFrame with order information
            wave_size: Number of orders per wave
            
        Returns:
            DataFrame with wave assignments
        """
        logger.info("Creating picking waves")
        
        wave_size = wave_size or self.batch_size
        df = orders_df.copy()
        
        # Sort by priority
        if 'priority' in df.columns:
            df = df.sort_values('priority')
        
        # Assign wave numbers
        df['wave_id'] = [(i // wave_size) + 1 for i in range(len(df))]
        
        logger.info(f"Created {df['wave_id'].max()} picking waves")
        
        return df
    
    def create_picking_batches(
        self,
        picks_df: pd.DataFrame,
        batch_size: int = None
    ) -> pd.DataFrame:
        """
        Group picks into batches based on location proximity
        
        Args:
            picks_df: DataFrame with pick information
            batch_size: Maximum picks per batch
            
        Returns:
            DataFrame with batch assignments
        """
        logger.info("Creating picking batches")
        
        batch_size = batch_size or self.batch_size
        df = picks_df.copy()
        
        # Simple batching by location clustering
        # For now, group by zone first
        if 'zone' in df.columns:
            df = df.sort_values(['zone', 'location_id'])
        else:
            df = df.sort_values('location_id')
        
        # Assign batch numbers
        df['batch_id'] = [(i // batch_size) + 1 for i in range(len(df))]
        
        logger.info(f"Created {df['batch_id'].max()} picking batches")
        
        return df
    
    def zone_picking(
        self,
        picks_df: pd.DataFrame,
        locations_df: pd.DataFrame
    ) -> pd.DataFrame:
        """
        Organize picks by warehouse zones
        
        Args:
            picks_df: DataFrame with pick information
            locations_df: DataFrame with location information
            
        Returns:
            DataFrame with zone-based organization
        """
        logger.info("Organizing picks by zone")
        
        # Merge with location info to get zones
        df = picks_df.merge(
            locations_df[['location_id', 'zone']],
            on='location_id',
            how='left'
        )
        
        # Sort by zone and location
        df = df.sort_values(['zone', 'location_id'])
        
        # Assign zone sequence
        df['pick_sequence'] = range(1, len(df) + 1)
        
        zone_counts = df['zone'].value_counts()
        logger.info(f"Zone distribution: {zone_counts.to_dict()}")
        
        return df
    
    def optimize_picking(
        self,
        picks_df: pd.DataFrame,
        locations_df: pd.DataFrame,
        strategy: Optional[str] = None
    ) -> pd.DataFrame:
        """
        Apply picking optimization strategy
        
        Args:
            picks_df: DataFrame with pick orders
            locations_df: DataFrame with location information
            strategy: Picking strategy to use
            
        Returns:
            DataFrame with optimized picks
        """
        strategy = strategy or self.strategy
        logger.info(f"Optimizing picking with strategy: {strategy}")
        
        if strategy == 'wave':
            result = self.create_picking_waves(picks_df)
        elif strategy == 'batch':
            result = self.create_picking_batches(picks_df)
        elif strategy == 'zone':
            result = self.zone_picking(picks_df, locations_df)
        else:
            raise ValueError(f"Unknown picking strategy: {strategy}")
        
        # Add timestamp
        result['optimization_timestamp'] = datetime.now()
        
        logger.info("Picking optimization complete")
        
        return result
    
    def calculate_picking_metrics(
        self,
        picks_df: pd.DataFrame,
        locations_df: pd.DataFrame
    ) -> Dict[str, float]:
        """
        Calculate metrics for picking operations
        
        Args:
            picks_df: DataFrame with pick information
            locations_df: DataFrame with location information
            
        Returns:
            Dictionary of metrics
        """
        # Merge with location coords
        df = picks_df.merge(
            locations_df[['location_id', 'x', 'y', 'z']],
            on='location_id',
            how='left'
        )
        
        metrics = {
            'total_picks': len(df),
            'unique_locations': df['location_id'].nunique()
        }
        
        # Calculate average distance between consecutive picks
        if len(df) > 1:
            coords = df[['x', 'y', 'z']].values
            distances = []
            for i in range(len(coords) - 1):
                dist = np.linalg.norm(coords[i+1] - coords[i])
                distances.append(dist)
            
            metrics['avg_travel_distance'] = np.mean(distances)
            metrics['total_travel_distance'] = np.sum(distances)
        
        # Strategy-specific metrics
        if 'wave_id' in df.columns:
            metrics['num_waves'] = df['wave_id'].nunique()
            metrics['avg_picks_per_wave'] = len(df) / metrics['num_waves']
        
        if 'batch_id' in df.columns:
            metrics['num_batches'] = df['batch_id'].nunique()
            metrics['avg_picks_per_batch'] = len(df) / metrics['num_batches']
        
        if 'zone' in df.columns:
            metrics['zones_visited'] = df['zone'].nunique()
        
        logger.info(f"Picking metrics: {metrics}")
        
        return metrics
    
    def assign_pickers(
        self,
        picks_df: pd.DataFrame,
        num_pickers: int
    ) -> pd.DataFrame:
        """
        Assign picks to available pickers
        
        Args:
            picks_df: DataFrame with pick information
            num_pickers: Number of available pickers
            
        Returns:
            DataFrame with picker assignments
        """
        logger.info(f"Assigning picks to {num_pickers} pickers")
        
        df = picks_df.copy()
        
        # Simple round-robin assignment
        if 'wave_id' in df.columns:
            # Assign pickers per wave
            df['picker_id'] = df.groupby('wave_id').cumcount() % num_pickers + 1
        elif 'batch_id' in df.columns:
            # Assign pickers per batch
            df['picker_id'] = df['batch_id'] % num_pickers + 1
        else:
            # Simple round-robin
            df['picker_id'] = [i % num_pickers + 1 for i in range(len(df))]
        
        picker_counts = df['picker_id'].value_counts()
        logger.info(f"Picker workload: {picker_counts.to_dict()}")
        
        return df
