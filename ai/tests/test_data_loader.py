"""Tests for data loader"""

import unittest
from ai.core import DataLoader


class TestDataLoader(unittest.TestCase):
    
    def test_data_loader_init(self):
        """Test data loader initialization"""
        loader = DataLoader()
        self.assertIsNotNone(loader)


if __name__ == '__main__':
    unittest.main()
