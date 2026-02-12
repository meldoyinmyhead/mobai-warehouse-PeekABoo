"""
Picking Service
High-level API for picking optimization operations
"""

import pandas as pd
from typing import Dict, Optional
from datetime import datetime

from ..optimization import PickingOptimizer, RouteOptimizer
from ..core import DataLoader
from ..config.logging_config import get_logger

logger = get_logger("picking_service")


class PickingService:
    """Service layer for picking optimization"""
    
    def __init__(self, strategy: str = None):
        """
        Initialize PickingService
        
        Args:
            strategy: Picking strategy ('wave', 'batch', or 'zone')
        """
        self.optimizer = PickingOptimizer(strategy=strategy)
        self.route_optimizer = RouteOptimizer()
        self.data_loader = DataLoader()
    
    def optimize_picking_list(
        self,
        picks_df: pd.DataFrame,
        locations_df: pd.DataFrame,
        strategy: Optional[str] = None
    ) -> Dict:
        """
        Optimize picking list
        
        Args:
            picks_df: DataFrame with picks to optimize
            locations_df: DataFrame with location information
            strategy: Picking strategy to use
            
        Returns:
            Dictionary with optimized picks
        """
        logger.info("Optimizing picking list")
        
        try:
            # Optimize picks
            optimized_picks = self.optimizer.optimize_picking(
                picks_df,
                locations_df,
                strategy
            )
            
            # Calculate metrics
            metrics = self.optimizer.calculate_picking_metrics(
                optimized_picks,
                locations_df
            )
            
            return {
                'success': True,
                'picks': optimized_picks.to_dict(orient='records'),
                'metrics': metrics,
                'strategy': strategy or self.optimizer.strategy,
                'timestamp': datetime.now().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error optimizing picks: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'timestamp': datetime.now().isoformat()
            }
    
    def optimize_picking_route(
        self,
        picks_df: pd.DataFrame,
        locations_df: pd.DataFrame,
        start_location: str = 'DEPOT_001'
    ) -> Dict:
        """
        Optimize picking route to minimize travel distance
        
        Args:
            picks_df: DataFrame with picks
            locations_df: DataFrame with locations
            start_location: Starting location ID
            
        Returns:
            Dictionary with optimized route
        """
        logger.info("Optimizing picking route")
        
        try:
            # Optimize route
            optimized_route = self.route_optimizer.optimize_route_order(
                picks_df,
                locations_df,
                start_location
            )
            
            # Calculate metrics
            metrics = self.route_optimizer.calculate_route_metrics(optimized_route)
            
            return {
                'success': True,
                'route': optimized_route.to_dict(orient='records'),
                'metrics': metrics,
                'start_location': start_location,
                'timestamp': datetime.now().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error optimizing route: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'timestamp': datetime.now().isoformat()
            }
    
    def create_picking_waves(
        self,
        orders_df: pd.DataFrame,
        wave_size: int = None
    ) -> Dict:
        """
        Create picking waves from orders
        
        Args:
            orders_df: DataFrame with orders
            wave_size: Number of orders per wave
            
        Returns:
            Dictionary with wave assignments
        """
        logger.info("Creating picking waves")
        
        try:
            waves_df = self.optimizer.create_picking_waves(orders_df, wave_size)
            
            wave_summary = waves_df.groupby('wave_id').agg({
                'order_id': 'count',
                'product_id': 'nunique'
            }).reset_index()
            wave_summary.columns = ['wave_id', 'order_count', 'unique_products']
            
            return {
                'success': True,
                'waves': waves_df.to_dict(orient='records'),
                'summary': wave_summary.to_dict(orient='records'),
                'num_waves': int(waves_df['wave_id'].max()),
                'timestamp': datetime.now().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error creating waves: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'timestamp': datetime.now().isoformat()
            }
    
    def assign_pickers(
        self,
        picks_df: pd.DataFrame,
        num_pickers: int
    ) -> Dict:
        """
        Assign picks to available pickers
        
        Args:
            picks_df: DataFrame with picks
            num_pickers: Number of available pickers
            
        Returns:
            Dictionary with picker assignments
        """
        logger.info(f"Assigning picks to {num_pickers} pickers")
        
        try:
            assigned_picks = self.optimizer.assign_pickers(picks_df, num_pickers)
            
            # Calculate workload per picker
            workload = assigned_picks.groupby('picker_id').agg({
                'product_id': 'count'
            }).reset_index()
            workload.columns = ['picker_id', 'num_picks']
            
            return {
                'success': True,
                'assignments': assigned_picks.to_dict(orient='records'),
                'workload': workload.to_dict(orient='records'),
                'num_pickers': num_pickers,
                'timestamp': datetime.now().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error assigning pickers: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'timestamp': datetime.now().isoformat()
            }
    
    def optimize_multi_picker_routes(
        self,
        picks_df: pd.DataFrame,
        locations_df: pd.DataFrame,
        num_pickers: int,
        start_location: str = 'DEPOT_001'
    ) -> Dict:
        """
        Optimize routes for multiple pickers
        
        Args:
            picks_df: DataFrame with picks
            locations_df: DataFrame with locations
            num_pickers: Number of pickers
            start_location: Starting location
            
        Returns:
            Dictionary with optimized routes for all pickers
        """
        logger.info(f"Optimizing routes for {num_pickers} pickers")
        
        try:
            optimized_routes = self.route_optimizer.optimize_multi_picker_routes(
                picks_df,
                locations_df,
                num_pickers,
                start_location
            )
            
            # Calculate metrics per picker
            picker_metrics = []
            for picker_id in range(1, num_pickers + 1):
                picker_picks = optimized_routes[optimized_routes['picker_id'] == picker_id]
                if len(picker_picks) > 0:
                    metrics = {
                        'picker_id': picker_id,
                        'num_picks': len(picker_picks),
                        'route_distance': float(picker_picks['route_distance'].iloc[0]) if 'route_distance' in picker_picks.columns else 0
                    }
                    picker_metrics.append(metrics)
            
            return {
                'success': True,
                'routes': optimized_routes.to_dict(orient='records'),
                'picker_metrics': picker_metrics,
                'num_pickers': num_pickers,
                'timestamp': datetime.now().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error optimizing multi-picker routes: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'timestamp': datetime.now().isoformat()
            }
