"""
Scoring Functions
Location scoring logic for optimization
"""

import pandas as pd
import numpy as np
from typing import Dict, Optional

from ..config.settings import settings
from ..config.logging_config import get_logger

logger = get_logger("scoring_functions")


class LocationScorer:
    """Calculate scores for location assignment"""
    
    def __init__(
        self,
        distance_weight: float = None,
        frequency_weight: float = None,
        velocity_weight: float = None
    ):
        """
        Initialize LocationScorer
        
        Args:
            distance_weight: Weight for distance component
            frequency_weight: Weight for pick frequency component
            velocity_weight: Weight for demand velocity component
        """
        self.distance_weight = distance_weight or settings.DISTANCE_WEIGHT
        self.frequency_weight = frequency_weight or settings.FREQUENCY_WEIGHT
        self.velocity_weight = velocity_weight or settings.VELOCITY_WEIGHT
        
        # Normalize weights
        total = self.distance_weight + self.frequency_weight + self.velocity_weight
        self.distance_weight /= total
        self.frequency_weight /= total
        self.velocity_weight /= total
    
    def normalize_score(self, values: np.ndarray, inverse: bool = False) -> np.ndarray:
        """
        Normalize values to 0-1 range
        
        Args:
            values: Array of values to normalize
            inverse: If True, invert the normalized values (higher raw = lower score)
            
        Returns:
            Normalized array
        """
        min_val = values.min()
        max_val = values.max()
        
        if max_val - min_val == 0:
            return np.ones_like(values)
        
        normalized = (values - min_val) / (max_val - min_val)
        
        if inverse:
            normalized = 1 - normalized
        
        return normalized
    
    def calculate_distance_score(
        self,
        distances: np.ndarray,
        higher_is_better: bool = False
    ) -> np.ndarray:
        """
        Calculate score based on distance (lower distance = higher score)
        
        Args:
            distances: Array of distances from depot/reference point
            higher_is_better: If True, higher distance gets higher score
            
        Returns:
            Distance scores (0-1)
        """
        return self.normalize_score(distances, inverse=not higher_is_better)
    
    def calculate_frequency_score(self, frequencies: np.ndarray) -> np.ndarray:
        """
        Calculate score based on pick frequency (higher frequency = higher score)
        
        Args:
            frequencies: Array of pick frequencies
            
        Returns:
            Frequency scores (0-1)
        """
        return self.normalize_score(frequencies, inverse=False)
    
    def calculate_velocity_score(self, velocities: np.ndarray) -> np.ndarray:
        """
        Calculate score based on demand velocity (higher velocity = higher score)
        
        Args:
            velocities: Array of demand velocities
            
        Returns:
            Velocity scores (0-1)
        """
        return self.normalize_score(velocities, inverse=False)
    
    def calculate_composite_score(
        self,
        distance: Optional[np.ndarray] = None,
        frequency: Optional[np.ndarray] = None,
        velocity: Optional[np.ndarray] = None
    ) -> np.ndarray:
        """
        Calculate weighted composite score
        
        Args:
            distance: Distance values (lower is better)
            frequency: Frequency values (higher is better)
            velocity: Velocity values (higher is better)
            
        Returns:
            Composite scores (0-1)
        """
        scores = []
        weights = []
        
        if distance is not None:
            distance_score = self.calculate_distance_score(distance)
            scores.append(distance_score)
            weights.append(self.distance_weight)
        
        if frequency is not None:
            frequency_score = self.calculate_frequency_score(frequency)
            scores.append(frequency_score)
            weights.append(self.frequency_weight)
        
        if velocity is not None:
            velocity_score = self.calculate_velocity_score(velocity)
            scores.append(velocity_score)
            weights.append(self.velocity_weight)
        
        if not scores:
            raise ValueError("At least one score component must be provided")
        
        # Normalize weights
        weights = np.array(weights)
        weights = weights / weights.sum()
        
        # Calculate weighted average
        composite = sum(s * w for s, w in zip(scores, weights))
        
        return composite
    
    def score_locations_for_product(
        self,
        locations_df: pd.DataFrame,
        product_data: Dict,
        depot_distances: pd.Series
    ) -> pd.DataFrame:
        """
        Score all locations for a specific product
        
        Args:
            locations_df: DataFrame with location information
            product_data: Dictionary with product attributes
                         (velocity, frequency, priority, etc.)
            depot_distances: Series of distances from depot
            
        Returns:
            DataFrame with location scores
        """
        df = locations_df.copy()
        
        # Add depot distances
        df['depot_distance'] = df['location_id'].map(depot_distances)
        
        # Calculate scores
        distances = df['depot_distance'].values
        
        # Use product velocity and frequency as constants for all locations
        velocity_values = np.full(len(df), product_data.get('velocity', 1.0))
        frequency_values = np.full(len(df), product_data.get('frequency', 1.0))
        
        # Calculate composite score
        df['score'] = self.calculate_composite_score(
            distance=distances,
            frequency=frequency_values,
            velocity=velocity_values
        )
        
        # Sort by score (descending)
        df = df.sort_values('score', ascending=False)
        
        return df
    
    def score_storage_assignment(
        self,
        product_location_df: pd.DataFrame,
        product_attributes: pd.DataFrame,
        depot_distances: pd.Series
    ) -> pd.DataFrame:
        """
        Score existing storage assignments
        
        Args:
            product_location_df: DataFrame with product-location assignments
            product_attributes: DataFrame with product attributes
            depot_distances: Series of distances from depot
            
        Returns:
            DataFrame with assignment scores
        """
        logger.info("Scoring storage assignments")
        
        # Merge product attributes
        df = product_location_df.merge(
            product_attributes,
            on='product_id',
            how='left'
        )
        
        # Add depot distances
        df['depot_distance'] = df['location_id'].map(depot_distances)
        
        # Calculate composite scores
        df['assignment_score'] = self.calculate_composite_score(
            distance=df['depot_distance'].values,
            velocity=df['velocity'].values if 'velocity' in df.columns else None,
            frequency=df['frequency'].values if 'frequency' in df.columns else None
        )
        
        avg_score = df['assignment_score'].mean()
        logger.info(f"Average assignment score: {avg_score:.3f}")
        
        return df
