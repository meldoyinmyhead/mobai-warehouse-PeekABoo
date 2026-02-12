"""
Compute Distances
Pre-compute distance matrix for warehouse locations
"""

from ai.core import DataLoader, DistanceCalculator
from ai.config.logging_config import get_logger

logger = get_logger("compute_distances")


def compute_distances():
    """Compute and cache distance matrix"""
    logger.info("Computing distance matrix")
    
    # Load warehouse layout
    loader = DataLoader()
    _, _, warehouse_layout = loader.load_processed_data()
    
    # Compute distances
    calculator = DistanceCalculator(cache_enabled=True)
    distance_matrix = calculator.compute_distance_matrix(warehouse_layout, method='euclidean')
    
    logger.info(f"Distance matrix computed: {distance_matrix.shape}")
    logger.info("Distance matrix cached successfully")


if __name__ == "__main__":
    compute_distances()
