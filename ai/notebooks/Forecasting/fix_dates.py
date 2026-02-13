import json
import os

notebooks = [
    "02_preprocessing.ipynb",
    "04_evaluation.ipynb",
    "05_enhanced_forecasting_pipeline.ipynb"
]

def patch_notebook(filepath):
    print(f"Patching {filepath}...")
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            nb = json.load(f)
        
        modified = False
        for cell in nb['cells']:
            if cell['cell_type'] == 'code':
                new_source = []
                for line in cell['source']:
                    # Look for date conversion
                    if "pd.to_datetime" in line and "['date']" in line:
                        if ".dt.normalize()" not in line:
                            # Add normalization
                            line = line.replace("pd.to_datetime", "pd.to_datetime").replace(")\n", ").dt.normalize()\n").replace(")]\n", ").dt.normalize()]\n") 
                            # Handle simple case: df['date'] = pd.to_datetime(df['date'])
                            # The replacement logic needs to be robust. 
                            # Let's try appending .dt.normalize() if it's an assignment
                            if "=" in line and ".dt.normalize" not in line:
                                # Strip newline, add .dt.normalize(), add newline back
                                line = line.rstrip() + ".dt.normalize()\n"
                                print(f"  Modified line: {line.strip()}")
                                modified = True
                    new_source.append(line)
                cell['source'] = new_source
        
        if modified:
            with open(filepath, 'w', encoding='utf-8') as f:
                json.dump(nb, f, indent=1)
            print("  Saved.")
        else:
            print("  No changes needed.")

    except Exception as e:
        print(f"  Error: {e}")

if __name__ == "__main__":
    for nb in notebooks:
        if os.path.exists(nb):
            patch_notebook(nb)
        else:
            print(f"Skipping {nb} (not found)")
