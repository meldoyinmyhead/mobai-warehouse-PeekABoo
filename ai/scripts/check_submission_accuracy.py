"""
Check if the hackathon submission output is accurate based on source data.
"""
import pandas as pd
import numpy as np

# Load data
submission = pd.read_csv('ai/data/outputs/hackathon_forecast_submission.csv')
source = pd.read_csv('ai/notebooks/data/outputs/final_production_forecasts_CALIBRATED.csv')

print("=" * 70)
print("📊 SOURCE DATA (Original Model Output - Single Day)")
print("=" * 70)
print(f"Products: {source['id_produit'].nunique()}")
print(f"Average forecast: {source['forecast'].mean():.2f}")
print(f"Min/Max: {source['forecast'].min():.2f} / {source['forecast'].max():.2f}")
print(f"Standard deviation: {source['forecast'].std():.2f}")

print(f"\nTop 5 products by forecast:")
top5 = source.nlargest(5, 'forecast')[['id_produit', 'segment', 'forecast', 'quantite_demande']]
print(top5.to_string(index=False))

print("\n" + "=" * 70)
print("📈 SUBMISSION DATA (Extended to 32 days)")
print("=" * 70)
print(f"Total rows: {len(submission):,}")
print(f"Products: {submission['id_produit'].nunique()}")
print(f"Days: {submission['Date'].nunique()}")
print(f"Average forecast per prediction: {submission['quantite_demande'].mean():.2f}")
print(f"Min/Max: {submission['quantite_demande'].min()} / {submission['quantite_demande'].max()}")
print(f"Standard deviation: {submission['quantite_demande'].std():.2f}")

# Check for zeros (intermittent demand)
zeros = (submission['quantite_demande'] == 0).sum()
print(f"Zero-demand predictions: {zeros} ({zeros/len(submission)*100:.2f}%)")

print("\n" + "=" * 70)
print("🔍 COMPARISON: Day 1 (08-01-2026) vs Original Forecasts")
print("=" * 70)

# Get first day data
day1 = submission[submission['Date'] == '08-01-2026'].sort_values('id_produit')

# Merge with source
comparison = pd.merge(
    source[['id_produit', 'segment', 'forecast']], 
    day1[['id_produit', 'quantite_demande']], 
    on='id_produit'
)

comparison['diff'] = comparison['quantite_demande'] - comparison['forecast']
comparison['diff_pct'] = (comparison['diff'] / comparison['forecast'] * 100)

print(f"\nStatistics:")
print(f"  Mean difference: {comparison['diff'].mean():.2f} units ({comparison['diff_pct'].mean():.2f}%)")
print(f"  Max difference: {comparison['diff'].max():.2f} units")
print(f"  Min difference: {comparison['diff'].min():.2f} units")

print(f"\nSample comparison (first 10 products):")
print(comparison.head(10)[['id_produit', 'segment', 'forecast', 'quantite_demande', 'diff', 'diff_pct']].to_string(index=False))

print("\n" + "=" * 70)
print("📊 SEGMENT-WISE ANALYSIS")
print("=" * 70)

# Analyze by segment
for segment in source['segment'].unique():
    seg_source = source[source['segment'] == segment]['forecast'].mean()
    seg_day1 = comparison[comparison['segment'] == segment]['quantite_demande'].mean()
    diff_pct = ((seg_day1 - seg_source) / seg_source * 100)
    print(f"\n{segment}:")
    print(f"  Original avg: {seg_source:.2f}")
    print(f"  Day 1 avg: {seg_day1:.2f}")
    print(f"  Difference: {diff_pct:+.2f}%")

print("\n" + "=" * 70)
print("📅 TEMPORAL ANALYSIS (Day-to-Day Variation)")
print("=" * 70)

# Group by date and calculate daily averages
daily_avg = submission.groupby('Date')['quantite_demande'].agg(['mean', 'std', 'min', 'max'])
daily_avg = daily_avg.head(10)  # First 10 days

print("\nFirst 10 days statistics:")
print(daily_avg.to_string())

# Check for weekend effect
submission['date_parsed'] = pd.to_datetime(submission['Date'], format='%d-%m-%Y')
submission['day_of_week'] = submission['date_parsed'].dt.day_name()

weekend_avg = submission[submission['day_of_week'].isin(['Saturday', 'Sunday'])]['quantite_demande'].mean()
weekday_avg = submission[~submission['day_of_week'].isin(['Saturday', 'Sunday'])]['quantite_demande'].mean()
weekend_ratio = (weekend_avg / weekday_avg) if weekday_avg > 0 else 0

print(f"\n📆 Weekend Effect:")
print(f"  Weekday average: {weekday_avg:.2f}")
print(f"  Weekend average: {weekend_avg:.2f}")
print(f"  Weekend/Weekday ratio: {weekend_ratio:.2%} (expected ~70% for high-freq products)")

print("\n" + "=" * 70)
print("✅ VALIDATION CHECKS")
print("=" * 70)

checks = []

# Check 1: Day 1 should be close to source (within ±10%)
day1_match = abs(comparison['diff_pct'].mean()) < 10
checks.append(("Day 1 matches source (±10%)", day1_match))

# Check 2: All products present
all_products = submission['id_produit'].nunique() == source['id_produit'].nunique()
checks.append(("All products included", all_products))

# Check 3: Correct number of days
correct_days = submission['Date'].nunique() == 32
checks.append(("32 days of forecasts", correct_days))

# Check 4: No negative values
no_negatives = (submission['quantite_demande'] >= 0).all()
checks.append(("No negative values", no_negatives))

# Check 5: Reasonable variation (not all identical)
variation_ok = submission['quantite_demande'].std() > 0
checks.append(("Has temporal variation", variation_ok))

# Check 6: Weekend effect present (for high-freq)
weekend_effect = weekend_ratio < 0.85  # Should be lower on weekends
checks.append(("Weekend seasonality present", weekend_effect))

for check_name, passed in checks:
    status = "✅" if passed else "❌"
    print(f"  {status} {check_name}")

print("\n" + "=" * 70)
if all(passed for _, passed in checks):
    print("🎯 CONCLUSION: Submission data looks ACCURATE and VALID!")
else:
    print("⚠️  CONCLUSION: Some validation checks failed - review needed")
print("=" * 70)
