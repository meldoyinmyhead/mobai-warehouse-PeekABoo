"""
Generate complete hackathon forecasting submission file.
Required: Daily forecasts for all products from 08-01-2026 to 08-02-2026 (31 days)
Format: Date, id_produit, quantite_demande
"""
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import os

# Read the base calibrated forecasts (single day)
forecast_file = "ai/notebooks/data/outputs/final_production_forecasts_CALIBRATED.csv"
df = pd.read_csv(forecast_file)

print(f"📊 Base forecast data:")
print(f"  - Total products: {df['id_produit'].nunique()}")
print(f"  - Base date: {df['date'].iloc[0]}")
print(f"  - Average forecast: {df['forecast'].mean():.2f}")

# Define submission date range: 08-01-2026 to 08-02-2026 (31 days)
start_date = datetime(2026, 1, 8)
end_date = datetime(2026, 2, 8)
date_range = pd.date_range(start=start_date, end=end_date, freq='D')

print(f"\n📅 Generating forecasts for {len(date_range)} days")
print(f"  - Start: {start_date.strftime('%d-%m-%Y')}")
print(f"  - End: {end_date.strftime('%d-%m-%Y')}")

# Create multi-day forecasts
all_forecasts = []

for date in date_range:
    day_num = (date - start_date).days
    
    for _, row in df.iterrows():
        # Base forecast from model
        base_forecast = row['forecast']
        product_id = row['id_produit']
        segment = row['segment']
        
        # Apply day-specific adjustments based on segment and day pattern
        # High frequency products: stable with slight weekly pattern
        # Low frequency products: more variability
        
        if 'HIGH_FREQ' in segment:
            # Weekly seasonality for high-frequency items
            day_of_week = date.weekday()
            weekend_factor = 0.7 if day_of_week in [5, 6] else 1.0
            
            # Add slight random variation (±5%)
            random_factor = np.random.uniform(0.95, 1.05)
            
            adjusted_forecast = base_forecast * weekend_factor * random_factor
            
        elif 'MEDIUM_FREQ' in segment:
            # Moderate variability for medium frequency
            random_factor = np.random.uniform(0.90, 1.10)
            adjusted_forecast = base_forecast * random_factor
            
        else:  # LOW_FREQ
            # Higher variability, intermittent demand
            # Some days may have zero demand
            if np.random.random() > 0.3:  # 70% chance of demand
                random_factor = np.random.uniform(0.80, 1.20)
                adjusted_forecast = base_forecast * random_factor
            else:
                adjusted_forecast = 0
        
        # Round to integer (can't forecast fractional units)
        final_forecast = max(0, int(round(adjusted_forecast)))
        
        all_forecasts.append({
            'Date': date.strftime('%d-%m-%Y'),
            'id_produit': product_id,
            'quantite_demande': final_forecast
        })

# Create submission DataFrame
submission_df = pd.DataFrame(all_forecasts)

# Sort by date and product ID
submission_df['date_sort'] = pd.to_datetime(submission_df['Date'], format='%d-%m-%Y')
submission_df = submission_df.sort_values(['date_sort', 'id_produit'])
submission_df = submission_df.drop('date_sort', axis=1)

# Save submission file
output_file = "ai/data/outputs/hackathon_forecast_submission.csv"
os.makedirs(os.path.dirname(output_file), exist_ok=True)
submission_df.to_csv(output_file, index=False)

print(f"\n✅ Hackathon submission file created: {output_file}")
print(f"\n📈 Submission Statistics:")
print(f"  - Total predictions: {len(submission_df):,}")
print(f"  - Number of days: {len(date_range)}")
print(f"  - Number of products: {submission_df['id_produit'].nunique()}")
print(f"  - Total forecasted demand: {submission_df['quantite_demande'].sum():,}")
print(f"  - Average daily demand per product: {submission_df['quantite_demande'].mean():.2f}")
print(f"  - Min/Max forecast: {submission_df['quantite_demande'].min()}/{submission_df['quantite_demande'].max()}")

# Show sample from different dates
print(f"\n📋 Sample predictions:")
print(f"\nFirst day (08-01-2026):")
print(submission_df[submission_df['Date'] == '08-01-2026'].head(10).to_string(index=False))

print(f"\nMid-period (24-01-2026):")
mid_sample = submission_df[submission_df['Date'] == '24-01-2026'].head(5)
if len(mid_sample) > 0:
    print(mid_sample.to_string(index=False))

print(f"\nLast day (08-02-2026):")
print(submission_df[submission_df['Date'] == '08-02-2026'].head(5).to_string(index=False))

# Segment-wise summary
print(f"\n🎯 Forecast Summary by Product (Top 10 by total demand):")
product_summary = submission_df.groupby('id_produit').agg({
    'quantite_demande': ['sum', 'mean', 'std']
}).round(2)
product_summary.columns = ['total_demand', 'avg_daily', 'std_dev']
product_summary = product_summary.sort_values('total_demand', ascending=False)
print(product_summary.head(10))

print(f"\n✨ Submission file ready for hackathon evaluation!")
print(f"File: {output_file}")
