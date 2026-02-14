import pandas as pd
import os

file_path = r"f:\summer\PeekABoo\wms\WMS_Hackathon_DataPack_Templates_FR_FV_B7_ONLY.xlsx"

if not os.path.exists(file_path):
    print(f"File not found: {file_path}")
    exit(1)

try:
    xl = pd.ExcelFile(file_path)
    print(f"Sheets: {[f'|{s}|' for s in xl.sheet_names]}")
    
    for sheet in xl.sheet_names:
        print(f"\n--- Sheet: |{sheet}| ---")
        df = pd.read_excel(file_path, sheet_name=sheet, nrows=5)
        print(df.columns.tolist())
        print(df.head())
except Exception as e:
    print(f"Error: {e}")
