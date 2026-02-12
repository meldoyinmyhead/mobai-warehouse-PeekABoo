"""
Storage Optimizer
Optimal storage location assignment based on product characteristics
"""

import pandas as pd
import numpy as np
from typing import Dict, List, Optional, Tuple

from .scoring_functions import LocationScorer
from ..core import DistanceCalculator, ProductSegmentation
from ..config.settings import settings
from ..config.logging_config import get_logger

logger = get_logger("storage_optimizer")


class StorageOptimizer:
    """Optimize storage location assignments"""
    
    def __init__(
        self,
        distance_weight: float = None,
        frequency_weight: float = None,
        velocity_weight: float = None
    ):
        """
        Initialize StorageOptimizer
        
        Args:
            distance_weight: Weight for distance factor
            frequency_weight: Weight for frequency factor
            velocity_weight: Weight for velocity factor
        """
        self.distance_weight = distance_weight or settings.DISTANCE_WEIGHT
        self.frequency_weight = frequency_weight or settings.FREQUENCY_WEIGHT
        self.velocity_weight = velocity_weight or settings.VELOCITY_WEIGHT
        
        self.scorer = LocationScorer(
            distance_weight=self.distance_weight,
            frequency_weight=self.frequency_weight,
            velocity_weight=self.velocity_weight
        )
        
        self.distance_calculator = DistanceCalculator()
    
    def assign_storage_zones(
        self,
        product_segments: pd.DataFrame
    ) -> pd.DataFrame:
        """
        Assign products to storage zones based on ABC-XYZ segment
        
        Args:
            product_segments: DataFrame with product segments
            
        Returns:
            DataFrame with storage zone assignments
        """
        logger.info("Assigning storage zones based on product segments")
        
        df = product_segments.copy()
        
        # Storage zone mapping based on segment
        zone_mapping = {
            'AX': 'PICKING',  # High value, low variability -> Fast picking
            'AY': 'PICKING',
            'AZ': 'RESERVE',  # High value, high variability -> Reserve
            'BX': 'PICKING',
            'BY': 'PICKING',
            'BZ': 'RESERVE',
            'CX': 'RESERVE',
            'CY': 'RESERVE',
            'CZ': 'BULK'      # Low value, high variability -> Bulk storage
        }
        
        df['storage_zone'] = df['segment'].map(zone_mapping)
        df['storage_zone'] = df['storage_zone'].fillna('RESERVE')
        
        zone_counts = df['storage_zone'].value_counts()
        logger.info(f"Zone distribution: {zone_counts.to_dict()}")
        
        return df
    
    def assign_storage_locations(
        self,
        products_df: pd.DataFrame,
        locations_df: pd.DataFrame,
        depot_location: str = 'DEPOT_001'
    ) -> pd.DataFrame:
        """
        Assign specific storage locations to products
        
        Args:
            products_df: DataFrame with products and zones
            locations_df: DataFrame with available locations
            depot_location: ID of depot location
            
        Returns:
            DataFrame with location assignments
        """
        logger.info("Assigning storage locations to products")
        
        # Compute distance from depot if not already done
        if self.distance_calculator.distance_matrix is None:
            self.distance_calculator.compute_distance_matrix(locations_df)
        
        depot_distances = self.distance_calculator.get_distance_from_depot(
            locations_df, depot_location
        )
        
        assignments = []
        
        # Group products by zone
        for zone in products_df['storage_zone'].unique():
            logger.info(f"Processing zone: {zone}")
            
            zone_products = products_df[products_df['storage_zone'] == zone].copy()
            zone_locations = locations_df[locations_df['zone'] == zone].copy()
            
            if len(zone_locations) == 0:
                logger.warning(f"No locations available for zone {zone}")
                continue
            
            # Add depot distance to locations
            zone_locations['depot_distance'] = zone_locations['location_id'].map(
                depot_distances
            )
            
            # Sort products by priority (descending)
            zone_products = zone_products.sort_values('priority_score', ascending=False)
            
            # Sort locations by distance from depot (ascending)
            zone_locations = zone_locations.sort_values('depot_distance')
            
            # Assign products to locations (greedy)
            for idx, product in zone_products.iterrows():
                if len(zone_locations) == 0:
                    logger.warning(f"No more locations available in zone {zone}")
                    break
                
                # Get best location for this product
                location = zone_locations.iloc[0]
                
                assignment = {
                    'product_id': product['product_id'],
                    'location_id': location['location_id'],
                    'storage_zone': zone,
                    'depot_distance': location['depot_distance'],
                    'priority_score': product['priority_score'],
                    'segment': product.get('segment', None)
                }
                
                assignments.append(assignment)
                
                # Remove assigned location
                zone_locations = zone_locations.iloc[1:]
        
        assignments_df = pd.DataFrame(assignments)
        
        logger.info(f"Assigned {len(assignments_df)} products to locations")
        
        return assignments_df
    
    def optimize_storage(
        self,
        products_df: pd.DataFrame,
        locations_df: pd.DataFrame,
        demand_df: Optional[pd.DataFrame] = None
    ) -> pd.DataFrame:
        """
        Full storage optimization pipeline
        
        Args:
            products_df: DataFrame with product attributes
            locations_df: DataFrame with warehouse locations
            demand_df: Optional demand history for segmentation
            
        Returns:
            DataFrame with optimized storage assignments
        """
        logger.info("Starting storage optimization")
        
        # If demand data provided, perform segmentation
        if demand_df is not None:
            segmenter = ProductSegmentation()
            product_segments = segmenter.segment_products(demand_df)
            
            # Merge with product attributes
            products_df = products_df.merge(
                product_segments[['product_id', 'segment', 'priority_score', 'velocity']],
                on='product_id',
                how='left'
            )
        
        # Assign storage zones
        products_df = self.assign_storage_zones(products_df)
        
        # Assign specific locations
        assignments = self.assign_storage_locations(products_df, locations_df)
        
        logger.info("Storage optimization complete")
        
        return assignments
    
    def calculate_storage_metrics(
        self,
        assignments_df: pd.DataFrame
    ) -> Dict[str, float]:
        """
        Calculate metrics for storage assignments
        
        Args:
            assignments_df: DataFrame with storage assignments
            
        Returns:
            Dictionary of metrics
        """
        metrics = {
            'total_products': len(assignments_df),
            'avg_depot_distance': assignments_df['depot_distance'].mean(),
            'min_depot_distance': assignments_df['depot_distance'].min(),
            'max_depot_distance': assignments_df['depot_distance'].max(),
            'zones_used': assignments_df['storage_zone'].nunique()
        }
        
        # Zone distribution
        zone_dist = assignments_df['storage_zone'].value_counts().to_dict()
        metrics['zone_distribution'] = zone_dist
        
        logger.info(f"Storage metrics: {metrics}")
        
        return metrics
