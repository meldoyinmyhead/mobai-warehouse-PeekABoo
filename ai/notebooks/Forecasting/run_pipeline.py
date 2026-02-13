import json, os, subprocess, sys
p = r'd:\Warehouse\mobai-warehouse-PeekABoo\ai\notebooks\Forecasting\05_enhanced_forecasting_pipeline.ipynb'
t = r'd:\Warehouse\mobai-warehouse-PeekABoo\ai\notebooks\Forecasting\temp_pipeline_runner.py'
print(f"Loading {p}")
with open(p, 'r', encoding='utf-8') as f: nb = json.load(f)
code = []
for c in nb['cells']:
    if c['cell_type'] == 'code':
        s = "".join(c['source'])
        lines = [l for l in s.split('\n') if not l.strip().startswith('%') and not l.strip().startswith('!')]
        code.append("\n".join(lines))
full = "\n\n".join(code)
with open(t, 'w', encoding='utf-8') as f: f.write(full)
print(f"Running {t}")
subprocess.run([sys.executable, t], check=True)
",Complexity:1,Description:
