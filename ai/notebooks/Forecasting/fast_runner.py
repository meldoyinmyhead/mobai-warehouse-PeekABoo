import json, sys, os, types; 
m = types.ModuleType('matplotlib'); 
m.pyplot = types.ModuleType('pyplot'); 
m.pyplot.show = lambda: None; 
m.pyplot.figure = lambda *a,**k: None; 
m.pyplot.subplot = lambda *a,**k: None; 
m.pyplot.plot = lambda *a,**k: None; 
m.pyplot.title = lambda *a,**k: None; 
m.pyplot.legend = lambda *a,**k: None; 
m.pyplot.xticks = lambda *a,**k: None; 
m.pyplot.scatter = lambda *a,**k: None; 
m.pyplot.tight_layout = lambda *a,**k: None; 
sys.modules['matplotlib'] = m; 
sys.modules['matplotlib.pyplot'] = m.pyplot; 
s = types.ModuleType('seaborn'); 
s.set_style = lambda *a,**k: None; 
sys.modules['seaborn'] = s; 
p = r'd:\Warehouse\mobai-warehouse-PeekABoo\ai\notebooks\Forecasting\05_enhanced_forecasting_pipeline.ipynb'; 
with open(p,'r',encoding='utf-8') as f: nb=json.load(f); 
code = []; 
for c in nb['cells']: 
    if c['cell_type']=='code': 
        src = ''.join(c['source']); 
        lines = [l for l in src.split('\n') if not l.strip().startswith('%') and not l.strip().startswith('!')]; 
        code.append('\n'.join(lines)); 
full_code = '\n'.join(code); 
exec(full_code)
