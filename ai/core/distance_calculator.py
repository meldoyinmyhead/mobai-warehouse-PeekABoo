"""
Distance Calculator
Calculate distances between warehouse locations
"""

import pandas as pd
import numpy as np
from typing import Dict, Tuple, Optional
from scipy.spatial.distance import cdist
import pickle

from ..config.settings import settings
from ..config.logging_config import get_logger

logger = get_logger("distance_calculator")


class DistanceCalculator:
    """Calculate and manage distances between warehouse locations"""
    
    def __init__(self, cache_enabled: bool = True):
        """
        Initialize DistanceCalculator
        
        Args:
            cache_enabled: Whether to cache computed distances
        """
        self.cache_enabled = cache_enabled and settings.ENABLE_CACHE
        self.distance_matrix: Optional[pd.DataFrame] = None
        self.cache_file = settings.CACHE_DIR / "distance_matrix.pkl"
    
    def euclidean_distance(
        self,
        point1: Tuple[float, float, float],
        point2: Tuple[float, float, float]
    ) -> float:
        """
        Calculate Euclidean distance between two 3D points
        
        Args:
            point1: (x, y, z) coordinates
            point2: (x, y, z) coordinates
            
        Returns:
            Euclidean distance
        """
        return np.sqrt(
            (point1[0] - point2[0]) ** 2 +
            (point1[1] - point2[1]) ** 2 +
            (point1[2] - point2[2]) ** 2
        )
    
    def manhattan_distance(
        self,
        point1: Tuple[float, float, float],
        point2: Tuple[float, float, float]
    ) -> float:
        """
        Calculate Manhattan distance between two 3D points
        
        Args:
            point1: (x, y, z) coordinates
            point2: (x, y, z) coordinates
            
        Returns:
            Manhattan distance
        """
        return (
            abs(point1[0] - point2[0]) +
            abs(point1[1] - point2[1]) +
            abs(point1[2] - point2[2])
        )
    
    def compute_distance_matrix(
        self,
        layout_df: pd.DataFrame,
        method: str = 'euclidean'
    ) -> pd.DataFrame:
        """
        Compute pairwise distance matrix for all locations
        
        Args:
            layout_df: DataFrame with location coordinates
            method: Distance metric ('euclidean' or 'manhattan')
            
        Returns:
            Distance matrix DataFrame
        """
        logger.info(f"Computing {method} distance matrix")
        
        # Extract coordinates
        locations = layout_df['location_id'].values
        coords = layout_df[['x', 'y', 'z']].values
        
        # Compute distances
        if method == 'euclidean':
            distances = cdist(coords, coords, metric='euclidean')
        elif method == 'manhattan':
            distances = cdist(coords, coords, metric='cityblock')
        else:
            raise ValueError(f"Unknown distance method: {method}")
        
        # Create DataFrame
        self.distance_matrix = pd.DataFrame(
            distances,
            index=locations,
            columns=locations
        )
        
        logger.info(f"Distance matrix shape: {self.distance_matrix.shape}")
        
        # Cache if enabled
        if self.cache_enabled:
            self.save_cache()
        
        return self.distance_matrix
    
    def get_distance(
        self,
        location1: str,
        location2: str
    ) -> float:
        """
        Get distance between two locations
        
        Args:
            location1: First location ID
            location2: Second location ID
            
        Returns:
            Distance value
        """
        if self.distance_matrix is None:
            raise ValueError("Distance matrix not computed. Call compute_distance_matrix first.")
        
        return self.distance_matrix.loc[location1, location2]
    
    def get_nearest_locations(
        self,
        location_id: str,
        n: int = 5,
        exclude_same: bool = True
    ) -> pd.Series:
        """
        Get nearest locations to a given location
        
        Args:
            location_id: Reference location ID
            n: Number of nearest locations to return
            exclude_same: Whether to exclude the location itself
            
        Returns:
            Series of nearest locations with distances
        """
        if self.distance_matrix is None:
            raise ValueError("Distance matrix not computed. Call compute_distance_matrix first.")
        
        distances = self.distance_matrix.loc[location_id].sort_values()
        
        if exclude_same:
            distances = distances[distances.index != location_id]
        
        return distances.head(n)
    
    def compute_total_distance(
        self,
        route: list
    ) -> float:
        """
        Compute total distance for a route (list of locations)
        
        Args:
            route: List of location IDs in order
            
        Returns:
            Total route distance
        """
        if self.distance_matrix is None:
            raise ValueError("Distance matrix not computed. Call compute_distance_matrix first.")
        
        if len(route) < 2:
            return 0.0
        
        total_distance = 0.0
        for i in range(len(route) - 1):
            total_distance += self.get_distance(route[i], route[i + 1])
        
        return total_distance
    
    def get_distance_from_depot(
        self,
        layout_df: pd.DataFrame,
        depot_location: str = 'DEPOT_001'
    ) -> pd.Series:
        """
        Calculate distance from depot for all locations
        
        Args:
            layout_df: DataFrame with warehouse layout
            depot_location: Depot location ID
            
        Returns:
            Series of distances from depot
        """
        if self.distance_matrix is None:
            logger.info("Computing distance matrix")
            self.compute_distance_matrix(layout_df)
        
        return self.distance_matrix.loc[depot_location]
    
    def save_cache(self):
        """Save distance matrix to cache"""
        if self.distance_matrix is not None:
            with open(self.cache_file, 'wb') as f:
                pickle.dump(self.distance_matrix, f)
            logger.info(f"Saved distance matrix to cache: {self.cache_file}")
    
    def load_cache(self) -> bool:
        """
        Load distance matrix from cache
        
        Returns:
            True if loaded successfully, False otherwise
        """
        if self.cache_file.exists():
            try:
                with open(self.cache_file, 'rb') as f:
                    self.distance_matrix = pickle.load(f)
                logger.info(f"Loaded distance matrix from cache: {self.cache_file}")
                return True
            except Exception as e:
                logger.warning(f"Failed to load cache: {str(e)}")
                return False
        return False
