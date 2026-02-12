"""
Route Optimizer
Optimize picking routes using TSP/VRP algorithms
"""

import pandas as pd
import numpy as np
from typing import List, Tuple, Optional
from scipy.spatial.distance import cdist
from itertools import permutations

from ..core import DistanceCalculator
from ..config.settings import settings
from ..config.logging_config import get_logger

logger = get_logger("route_optimizer")


class RouteOptimizer:
    """Optimize picking routes (TSP/VRP)"""
    
    def __init__(self, max_distance: float = None):
        """
        Initialize RouteOptimizer
        
        Args:
            max_distance: Maximum route distance constraint
        """
        self.max_distance = max_distance or settings.MAX_PICK_DISTANCE
        self.distance_calculator = DistanceCalculator()
    
    def nearest_neighbor_tsp(
        self,
        locations: List[str],
        start_location: str,
        distance_matrix: pd.DataFrame
    ) -> Tuple[List[str], float]:
        """
        Solve TSP using nearest neighbor heuristic
        
        Args:
            locations: List of location IDs to visit
            start_location: Starting location ID
            distance_matrix: Pairwise distance matrix
            
        Returns:
            Tuple of (route, total_distance)
        """
        logger.info(f"Solving TSP for {len(locations)} locations")
        
        unvisited = set(locations)
        route = [start_location]
        current = start_location
        total_distance = 0
        
        if start_location in unvisited:
            unvisited.remove(start_location)
        
        while unvisited:
            # Find nearest unvisited location
            nearest = None
            min_distance = float('inf')
            
            for loc in unvisited:
                dist = distance_matrix.loc[current, loc]
                if dist < min_distance:
                    min_distance = dist
                    nearest = loc
            
            if nearest is not None:
                route.append(nearest)
                total_distance += min_distance
                current = nearest
                unvisited.remove(nearest)
        
        # Return to start
        if len(route) > 1:
            total_distance += distance_matrix.loc[current, start_location]
            route.append(start_location)
        
        logger.info(f"TSP solution: {len(route)} stops, distance={total_distance:.2f}")
        
        return route, total_distance
    
    def optimize_route_order(
        self,
        picks_df: pd.DataFrame,
        locations_df: pd.DataFrame,
        start_location: str = 'DEPOT_001'
    ) -> pd.DataFrame:
        """
        Optimize the order of picks to minimize travel distance
        
        Args:
            picks_df: DataFrame with pick information
            locations_df: DataFrame with location coordinates
            start_location: Starting location for route
            
        Returns:
            DataFrame with optimized pick sequence
        """
        logger.info("Optimizing pick route order")
        
        # Compute distance matrix if not available
        if self.distance_calculator.distance_matrix is None:
            self.distance_calculator.compute_distance_matrix(locations_df)
        
        df = picks_df.copy()
        
        # Get unique locations to visit
        pick_locations = df['location_id'].unique().tolist()
        
        # Solve TSP
        optimal_route, total_distance = self.nearest_neighbor_tsp(
            pick_locations,
            start_location,
            self.distance_calculator.distance_matrix
        )
        
        # Create location to sequence mapping
        location_order = {loc: idx for idx, loc in enumerate(optimal_route)}
        
        # Assign pick sequence
        df['pick_sequence'] = df['location_id'].map(location_order)
        df = df.sort_values('pick_sequence')
        
        # Recalculate sequence numbers
        df['pick_sequence'] = range(1, len(df) + 1)
        
        # Add route metadata
        df['route_distance'] = total_distance
        df['start_location'] = start_location
        
        logger.info(f"Optimized route with distance={total_distance:.2f}")
        
        return df
    
    def split_route_by_distance(
        self,
        route: List[str],
        distance_matrix: pd.DataFrame,
        max_distance: float = None
    ) -> List[List[str]]:
        """
        Split long route into multiple sub-routes
        
        Args:
            route: List of location IDs
            distance_matrix: Distance matrix
            max_distance: Maximum distance per sub-route
            
        Returns:
            List of sub-routes
        """
        max_distance = max_distance or self.max_distance
        logger.info(f"Splitting route with max_distance={max_distance}")
        
        sub_routes = []
        current_route = [route[0]]
        current_distance = 0
        
        for i in range(1, len(route)):
            segment_distance = distance_matrix.loc[route[i-1], route[i]]
            
            if current_distance + segment_distance > max_distance and len(current_route) > 1:
                # Start new sub-route
                sub_routes.append(current_route)
                current_route = [route[i]]
                current_distance = 0
            else:
                current_route.append(route[i])
                current_distance += segment_distance
        
        # Add last sub-route
        if current_route:
            sub_routes.append(current_route)
        
        logger.info(f"Split into {len(sub_routes)} sub-routes")
        
        return sub_routes
    
    def optimize_multi_picker_routes(
        self,
        picks_df: pd.DataFrame,
        locations_df: pd.DataFrame,
        num_pickers: int,
        start_location: str = 'DEPOT_001'
    ) -> pd.DataFrame:
        """
        Optimize routes for multiple pickers
        
        Args:
            picks_df: DataFrame with picks
            locations_df: DataFrame with locations
            num_pickers: Number of pickers
            start_location: Starting location
            
        Returns:
            DataFrame with picker and route assignments
        """
        logger.info(f"Optimizing routes for {num_pickers} pickers")
        
        # Compute distance matrix
        if self.distance_calculator.distance_matrix is None:
            self.distance_calculator.compute_distance_matrix(locations_df)
        
        df = picks_df.copy()
        
        # Divide picks among pickers
        picks_per_picker = len(df) // num_pickers
        
        results = []
        
        for picker_id in range(1, num_pickers + 1):
            start_idx = (picker_id - 1) * picks_per_picker
            end_idx = start_idx + picks_per_picker if picker_id < num_pickers else len(df)
            
            picker_picks = df.iloc[start_idx:end_idx].copy()
            
            if len(picker_picks) == 0:
                continue
            
            # Optimize route for this picker
            optimized = self.optimize_route_order(
                picker_picks,
                locations_df,
                start_location
            )
            
            optimized['picker_id'] = picker_id
            results.append(optimized)
        
        # Combine results
        result_df = pd.concat(results, ignore_index=True)
        
        logger.info(f"Optimized routes for {num_pickers} pickers")
        
        return result_df
    
    def calculate_route_metrics(
        self,
        route_df: pd.DataFrame
    ) -> dict:
        """
        Calculate metrics for optimized routes
        
        Args:
            route_df: DataFrame with route information
            
        Returns:
            Dictionary of metrics
        """
        metrics = {
            'total_stops': len(route_df),
            'unique_locations': route_df['location_id'].nunique()
        }
        
        if 'route_distance' in route_df.columns:
            metrics['total_distance'] = route_df['route_distance'].iloc[0]
        
        if 'picker_id' in route_df.columns:
            metrics['num_pickers'] = route_df['picker_id'].nunique()
            picker_stops = route_df.groupby('picker_id').size().to_dict()
            metrics['stops_per_picker'] = picker_stops
        
        logger.info(f"Route metrics: {metrics}")
        
        return metrics
