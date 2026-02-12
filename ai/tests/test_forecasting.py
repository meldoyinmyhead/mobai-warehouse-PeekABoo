"""Tests for forecasting module"""

import unittest
import pandas as pd
import numpy as np

from ai.forecasting.models import NaiveBaseline, RandomForestForecaster


class TestForecasting(unittest.TestCase):
    
    def setUp(self):
        """Set up test data"""
        self.X_train = pd.DataFrame({'feature1': range(100), 'feature2': range(100, 200)})
        self.y_train = pd.Series(range(100))
        self.X_test = pd.DataFrame({'feature1': range(10), 'feature2': range(100, 110)})
    
    def test_naive_baseline(self):
        """Test naive baseline model"""
        model = NaiveBaseline()
        model.train(self.X_train, self.y_train)
        predictions = model.predict(self.X_test)
        
        self.assertEqual(len(predictions), len(self.X_test))
        self.assertTrue(all(predictions >= 0))
    
    def test_random_forest(self):
        """Test random forest model"""
        model = RandomForestForecaster(n_estimators=10)
        model.train(self.X_train, self.y_train)
        predictions = model.predict(self.X_test)
        
        self.assertEqual(len(predictions), len(self.X_test))
        self.assertTrue(model.is_trained)


if __name__ == '__main__':
    unittest.main()
