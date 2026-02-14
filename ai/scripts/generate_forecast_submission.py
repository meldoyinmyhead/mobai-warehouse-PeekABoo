"""
Generate forecasting submission file for hackathon evaluation.
Required format: Date, id_produit, quantite_demande
Date range: 08-01-2026 → 08-02-2026 (January 8 to February 8, 2026)
"""
import pandas as pd
from datetime import datetime, timedelta
import os

# Read the calibrated forecasts
forecast_file = "ai/notebooks/data/outputs/final_production_forecasts_CALIBRATED.csv"
df = pd.read_csv(forecast_file)

print(f"Total forecast rows: {len(df)}")
print(f"Unique dates: {df['date'].nunique()}")
print(f"Unique products: {df['id_produit'].nunique()}")
print(f"\nDate range in data:")
print(df['date'].unique()[:5])

# Convert date column to datetime
df['date'] = pd.to_datetime(df['date'])

# Define submission date range: 08-01-2026 to 08-02-2026 (Jan 8 to Feb 8)
start_date = datetime(2026, 1, 8)
end_date = datetime(2026, 2, 8)

# Filter forecasts for the submission period
submission_df = df[(df['date'] >= start_date) & (df['date'] <= end_date)].copy()

print(f"\nForecasts in submission period: {len(submission_df)}")

# Create submission file with required format
# Round forecast to nearest integer for quantite_demande
submission_df['quantite_demande'] = submission_df['forecast'].round().astype(int)

# Format date as DD-MM-YYYY
submission_df['Date'] = submission_df['date'].dt.strftime('%d-%m-%Y')

# Select only required columns in exact order
submission_output = submission_df[['Date', 'id_produit', 'quantite_demande']].copy()

# Sort by date and product ID
submission_output = submission_output.sort_values(['Date', 'id_produit'])

# Save submission file
output_file = "ai/data/outputs/forecast_submission.csv"
os.makedirs(os.path.dirname(output_file), exist_ok=True)
submission_output.to_csv(output_file, index=False)

print(f"\n✅ Submission file created: {output_file}")
print(f"Total predictions: {len(submission_output)}")
print(f"\nFirst 10 rows:")
print(submission_output.head(10))
print(f"\nLast 5 rows:")
print(submission_output.tail(5))

# Generate summary statistics
print(f"\n📊 Submission Summary:")
print(f"Date range: {submission_output['Date'].min()} to {submission_output['Date'].max()}")
print(f"Number of products: {submission_output['id_produit'].nunique()}")
print(f"Total predictions: {len(submission_output)}")
print(f"Average demand per day: {submission_output['quantite_demande'].mean():.2f}")
print(f"Total forecasted demand: {submission_output['quantite_demande'].sum():,}")
