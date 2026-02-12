"""Tests for optimization module"""

import unittest
import pandas as pd

from ai.optimization import StorageOptimizer, PickingOptimizer


class TestOptimization(unittest.TestCase):
    
    def setUp(self):
        """Set up test data"""
        self.products_df = pd.DataFrame({
            'product_id': ['P1', 'P2', 'P3'],
            'segment': ['AX', 'BY', 'CZ'],
            'priority_score': [9, 6, 3]
        })
        
        self.locations_df = pd.DataFrame({
            'location_id': ['L1', 'L2', 'L3'],
            'zone': ['PICKING', 'RESERVE', 'BULK'],
            'x': [0, 10, 20],
            'y': [0, 10, 20],
            'z': [0, 0, 0]
        })
    
    def test_storage_zone_assignment(self):
        """Test storage zone assignment"""
        optimizer = StorageOptimizer()
        result = optimizer.assign_storage_zones(self.products_df)
        
        self.assertIn('storage_zone', result.columns)
        self.assertEqual(len(result), len(self.products_df))


if __name__ == '__main__':
    unittest.main()
