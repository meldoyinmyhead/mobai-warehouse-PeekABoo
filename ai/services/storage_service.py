"""
Storage Service
High-level API for storage optimization operations
"""

import pandas as pd
from typing import Dict, Optional
from datetime import datetime

from ..optimization import StorageOptimizer
from ..core import DataLoader, ProductSegmentation
from ..config.logging_config import get_logger

logger = get_logger("storage_service")


class StorageService:
    """Service layer for storage optimization"""
    
    def __init__(self):
        """Initialize StorageService"""
        self.optimizer = StorageOptimizer()
        self.data_loader = DataLoader()
    
    def optimize_storage_layout(
        self,
        products_df: pd.DataFrame,
        locations_df: pd.DataFrame,
        demand_df: Optional[pd.DataFrame] = None
    ) -> Dict:
        """
        Optimize storage layout for products
        
        Args:
            products_df: Product attributes DataFrame
            locations_df: Warehouse locations DataFrame
            demand_df: Historical demand data (optional)
            
        Returns:
            Dictionary with optimization results
        """
        logger.info("Optimizing storage layout")
        
        try:
            # Perform optimization
            assignments = self.optimizer.optimize_storage(
                products_df,
                locations_df,
                demand_df
            )
            
            # Calculate metrics
            metrics = self.optimizer.calculate_storage_metrics(assignments)
            
            return {
                'success': True,
                'assignments': assignments.to_dict(orient='records'),
                'metrics': metrics,
                'timestamp': datetime.now().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error optimizing storage: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'timestamp': datetime.now().isoformat()
            }
    
    def assign_storage_zones(
        self,
        products_df: pd.DataFrame,
        demand_df: pd.DataFrame
    ) -> Dict:
        """
        Assign products to storage zones based on ABC-XYZ analysis
        
        Args:
            products_df: Product attributes DataFrame
            demand_df: Historical demand data
            
        Returns:
            Dictionary with zone assignments
        """
        logger.info("Assigning storage zones")
        
        try:
            # Perform segmentation
            segmenter = ProductSegmentation()
            segments = segmenter.segment_products(demand_df)
            
            # Merge with products
            products_with_segments = products_df.merge(
                segments[['product_id', 'segment', 'abc_class', 'xyz_class', 'priority_score']],
                on='product_id',
                how='left'
            )
            
            # Assign zones
            zone_assignments = self.optimizer.assign_storage_zones(products_with_segments)
            
            # Summary
            zone_dist = zone_assignments['storage_zone'].value_counts().to_dict()
            segment_dist = zone_assignments['segment'].value_counts().to_dict()
            
            return {
                'success': True,
                'assignments': zone_assignments.to_dict(orient='records'),
                'zone_distribution': zone_dist,
                'segment_distribution': segment_dist,
                'timestamp': datetime.now().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error assigning storage zones: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'timestamp': datetime.now().isoformat()
            }
    
    def get_storage_recommendations(
        self,
        product_id: str,
        products_df: pd.DataFrame,
        locations_df: pd.DataFrame,
        demand_df: Optional[pd.DataFrame] = None,
        top_n: int = 5
    ) -> Dict:
        """
        Get top N storage location recommendations for a product
        
        Args:
            product_id: Product ID
            products_df: Product attributes
            locations_df: Available locations
            demand_df: Historical demand
            top_n: Number of recommendations
            
        Returns:
            Dictionary with recommendations
        """
        logger.info(f"Getting storage recommendations for product {product_id}")
        
        try:
            from ..optimization import LocationScorer
            
            # Get product info
            product_info = products_df[products_df['product_id'] == product_id]
            
            if len(product_info) == 0:
                return {
                    'success': False,
                    'error': f'Product {product_id} not found',
                    'timestamp': datetime.now().isoformat()
                }
            
            # Calculate product velocity if demand data provided
            velocity = 1.0
            if demand_df is not None:
                product_demand = demand_df[demand_df['product_id'] == product_id]
                if len(product_demand) > 0:
                    date_range = (product_demand['date'].max() - product_demand['date'].min()).days
                    velocity = product_demand['demand'].sum() / max(date_range, 1)
            
            # Score locations
            scorer = LocationScorer()
            
            # Compute distances
            if self.optimizer.distance_calculator.distance_matrix is None:
                self.optimizer.distance_calculator.compute_distance_matrix(locations_df)
            
            depot_distances = self.optimizer.distance_calculator.get_distance_from_depot(
                locations_df
            )
            
            product_data = {
                'velocity': velocity,
                'frequency': 1.0
            }
            
            scored_locations = scorer.score_locations_for_product(
                locations_df,
                product_data,
                depot_distances
            )
            
            recommendations = scored_locations.head(top_n)
            
            return {
                'success': True,
                'product_id': product_id,
                'recommendations': recommendations.to_dict(orient='records'),
                'timestamp': datetime.now().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error getting recommendations: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'timestamp': datetime.now().isoformat()
            }
