"""
Validate hackathon forecasting submission file.
Checks format, completeness, and compliance with requirements.
"""
import pandas as pd
from datetime import datetime

def validate_submission(file_path):
    """Validate the forecasting submission file."""
    print("🔍 HACKATHON SUBMISSION VALIDATION\n")
    print("=" * 60)
    
    errors = []
    warnings = []
    
    # 1. File exists and is readable
    try:
        df = pd.read_csv(file_path)
        print("✅ File exists and is readable")
    except Exception as e:
        print(f"❌ CRITICAL: Cannot read file - {e}")
        return False
    
    # 2. Check required columns
    required_columns = ['Date', 'id_produit', 'quantite_demande']
    if list(df.columns) == required_columns:
        print(f"✅ Correct columns: {required_columns}")
    else:
        errors.append(f"Incorrect columns. Expected: {required_columns}, Got: {list(df.columns)}")
        print(f"❌ Column mismatch")
    
    # 3. Check date format (DD-MM-YYYY)
    try:
        sample_dates = df['Date'].head(10)
        for date_str in sample_dates:
            datetime.strptime(date_str, '%d-%m-%Y')
        print("✅ Date format correct (DD-MM-YYYY)")
    except Exception as e:
        errors.append(f"Invalid date format: {e}")
        print(f"❌ Date format error")
    
    # 4. Check date range (08-01-2026 to 08-02-2026)
    try:
        df['date_parsed'] = pd.to_datetime(df['Date'], format='%d-%m-%Y')
        min_date = df['date_parsed'].min()
        max_date = df['date_parsed'].max()
        expected_start = datetime(2026, 1, 8)
        expected_end = datetime(2026, 2, 8)
        
        if min_date == expected_start and max_date == expected_end:
            print(f"✅ Date range: {min_date.strftime('%d-%m-%Y')} to {max_date.strftime('%d-%m-%Y')}")
        else:
            warnings.append(f"Date range mismatch. Expected: 08-01-2026 to 08-02-2026, Got: {min_date.strftime('%d-%m-%Y')} to {max_date.strftime('%d-%m-%Y')}")
            print(f"⚠️  Date range differs from expected")
    except Exception as e:
        errors.append(f"Date range validation error: {e}")
        print(f"❌ Date range error")
    
    # 5. Check product IDs are valid integers
    try:
        if df['id_produit'].dtype in ['int64', 'int32']:
            print(f"✅ Product IDs are integers")
        else:
            warnings.append("Product IDs should be integers")
            print(f"⚠️  Product IDs not integer type")
    except Exception as e:
        errors.append(f"Product ID validation error: {e}")
        print(f"❌ Product ID error")
    
    # 6. Check quantities are non-negative integers
    try:
        if df['quantite_demande'].dtype in ['int64', 'int32']:
            if (df['quantite_demande'] >= 0).all():
                print(f"✅ Quantities are non-negative integers")
            else:
                errors.append("Negative quantities found")
                print(f"❌ Negative quantities detected")
        else:
            warnings.append("Quantities should be integers")
            print(f"⚠️  Quantities not integer type")
    except Exception as e:
        errors.append(f"Quantity validation error: {e}")
        print(f"❌ Quantity error")
    
    # 7. Check completeness (all products for all dates)
    num_products = df['id_produit'].nunique()
    num_dates = df['Date'].nunique()
    expected_rows = num_products * num_dates
    actual_rows = len(df)
    
    if actual_rows == expected_rows:
        print(f"✅ Completeness: {num_products} products × {num_dates} days = {actual_rows} rows")
    else:
        warnings.append(f"Expected {expected_rows} rows ({num_products} × {num_dates}), got {actual_rows}")
        print(f"⚠️  Completeness warning")
    
    # 8. Check for missing values
    missing = df.isnull().sum().sum()
    if missing == 0:
        print(f"✅ No missing values")
    else:
        errors.append(f"Found {missing} missing values")
        print(f"❌ Missing values: {missing}")
    
    # 9. Statistical validation
    print("\n" + "=" * 60)
    print("📊 STATISTICAL SUMMARY\n")
    print(f"Total predictions: {len(df):,}")
    print(f"Number of products: {num_products}")
    print(f"Number of days: {num_dates}")
    print(f"Total forecasted demand: {df['quantite_demande'].sum():,}")
    print(f"Average demand per prediction: {df['quantite_demande'].mean():.2f}")
    print(f"Min/Max demand: {df['quantite_demande'].min()} / {df['quantite_demande'].max()}")
    print(f"Zero-demand predictions: {(df['quantite_demande'] == 0).sum()} ({(df['quantite_demande'] == 0).sum()/len(df)*100:.1f}%)")
    
    # Top products by total demand
    print("\n🏆 Top 5 Products by Total Demand:")
    top_products = df.groupby('id_produit')['quantite_demande'].sum().sort_values(ascending=False).head(5)
    for i, (prod_id, total) in enumerate(top_products.items(), 1):
        print(f"  {i}. Product {prod_id}: {total:,} units")
    
    # Summary
    print("\n" + "=" * 60)
    print("📋 VALIDATION SUMMARY\n")
    
    if len(errors) == 0 and len(warnings) == 0:
        print("✅ PASSED - Submission file is valid and ready!")
        print("\n🎯 File ready for hackathon submission")
        return True
    else:
        if errors:
            print(f"❌ FAILED - {len(errors)} critical error(s):")
            for i, err in enumerate(errors, 1):
                print(f"  {i}. {err}")
        if warnings:
            print(f"\n⚠️  {len(warnings)} warning(s):")
            for i, warn in enumerate(warnings, 1):
                print(f"  {i}. {warn}")
        
        return len(errors) == 0

if __name__ == "__main__":
    submission_file = "ai/data/outputs/hackathon_forecast_submission.csv"
    is_valid = validate_submission(submission_file)
    
    print("\n" + "=" * 60)
    if is_valid:
        print("✨ READY FOR SUBMISSION ✨")
        print(f"📁 File: {submission_file}")
    else:
        print("⚠️  PLEASE FIX ERRORS BEFORE SUBMITTING")
