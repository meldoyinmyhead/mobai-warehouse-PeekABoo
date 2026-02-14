"""
Multi-product route test — finds the optimal path from each product's
storage slot (floors 1–4) down to the ground floor, prints a summary
table, and visualizes every route.

Now with 3-chariot parallel system with timestamps!
"""

import pandas as pd
from datetime import datetime, timedelta
from pathlib import Path
from route_optimizer import RouteOptimizer

# ── Define the picking order: (product_id, quantity) ────────────────
ORDER = [
    ("31496", 2),     # known product, high stock
    ("31725", 3),     # highest stock product
    ("31554", 1),     # second highest
    ("35585", 2),     # third highest
    ("34015", 1),     # fourth
    ("31565", 1),     # good stock
    ("31730", 2),     # good stock
    ("34016", 1),     # good stock
    ("35574", 1),     # good stock
    ("31461", 3),     # good stock
]

product_ids  = [pid for pid, _ in ORDER]
quantities   = [qty for _, qty in ORDER]

# ── Build optimizer (loads grids, BFS, inventory — once) ────────────
print("⏳ Building warehouse model …")
opt = RouteOptimizer()
print("✓ Ready\n")

# ── Load product features for volume calculations ──────────────────
STORAGE_OPT_DIR = Path(__file__).resolve().parent / ".." / "storageOpt"
PRODUITS_CSV = STORAGE_OPT_DIR / "produits.csv"

produits_df = pd.read_csv(PRODUITS_CSV)
product_features = {}

def safe_float(val, default=0.0):
    """Safely convert value to float."""
    try:
        if pd.isna(val) or val == "" or val is None:
            return default
        return float(val)
    except (ValueError, TypeError):
        return default

for _, row in produits_df.iterrows():
    pid = str(row["id_produit"])
    product_features[pid] = {
        "nom": row.get("nom_produit", ""),
        "categorie": row.get("categorie", ""),
        "volume_m3": safe_float(row.get("volume pcs (m3)", 0)),
        "colisage_pal": safe_float(row.get("colisage palette", 0)),
    }

print(f"📦 Loaded {len(product_features)} product features\n")

# ── Define Chariot System ───────────────────────────────────────────
CHARIOTS = [
    {"id": 1, "palette_capacity": 3, "name": "Large Chariot", "speed_m_per_min": 50},
    {"id": 2, "palette_capacity": 1, "name": "Small Chariot A", "speed_m_per_min": 50},
    {"id": 3, "palette_capacity": 1, "name": "Small Chariot B", "speed_m_per_min": 50},
]

def palette_volume_for_product(pid: str) -> float:
    """Calculate volume of one palette for a given product."""
    feat = product_features.get(str(pid), {})
    volume_per_piece = feat.get("volume_m3", 0)
    colisage_pal = feat.get("colisage_pal", 1)
    if colisage_pal == 0:
        colisage_pal = 1
    return volume_per_piece * colisage_pal

def convert_palette_capacity_to_volume(num_palettes: int, avg_palette_volume: float) -> float:
    """Convert palette capacity to volume capacity."""
    return num_palettes * avg_palette_volume

# Calculate average palette volume
avg_palette_vol = 0.0
for pid, _ in ORDER:
    avg_palette_vol += palette_volume_for_product(pid)
avg_palette_vol /= len(ORDER) if ORDER else 1

print(f"📊 Average palette volume in order: {avg_palette_vol:.4f} m³")

# Set volume capacity for each chariot
for chariot in CHARIOTS:
    chariot["volume_capacity_m3"] = convert_palette_capacity_to_volume(
        chariot["palette_capacity"], avg_palette_vol
    )
    print(f"  {chariot['name']} (ID {chariot['id']}): "
          f"{chariot['palette_capacity']} palette(s) = {chariot['volume_capacity_m3']:.4f} m³ "
          f"@ {chariot['speed_m_per_min']} m/min")

print()

# ── Group items into chariot loads ──────────────────────────────────
def group_items_into_chariot_loads(order_items: list[tuple[str, int]]) -> list[dict]:
    """Group order items into chariot loads based on volume capacity."""
    all_units = []
    for pid, qty in order_items:
        feat = product_features.get(str(pid), {})
        volume = feat.get("volume_m3", 0)
        for unit in range(1, qty + 1):
            all_units.append({
                "product_id": str(pid),
                "unit": unit,
                "total_qty": qty,
                "volume_m3": volume,
            })
    
    chariot_loads = []
    chariot_idx = 0
    current_load = {
        "chariot_id": CHARIOTS[chariot_idx]["id"],
        "chariot_name": CHARIOTS[chariot_idx]["name"],
        "capacity_m3": CHARIOTS[chariot_idx]["volume_capacity_m3"],
        "speed_m_per_min": CHARIOTS[chariot_idx]["speed_m_per_min"],
        "items": [],
        "total_volume_m3": 0.0,
    }
    
    for unit in all_units:
        if current_load["total_volume_m3"] + unit["volume_m3"] > current_load["capacity_m3"]:
            if current_load["items"]:
                chariot_loads.append(current_load)
            
            chariot_idx = (chariot_idx + 1) % len(CHARIOTS)
            current_load = {
                "chariot_id": CHARIOTS[chariot_idx]["id"],
                "chariot_name": CHARIOTS[chariot_idx]["name"],
                "capacity_m3": CHARIOTS[chariot_idx]["volume_capacity_m3"],
                "speed_m_per_min": CHARIOTS[chariot_idx]["speed_m_per_min"],
                "items": [],
                "total_volume_m3": 0.0,
            }
        
        current_load["items"].append(unit)
        current_load["total_volume_m3"] += unit["volume_m3"]
    
    if current_load["items"]:
        chariot_loads.append(current_load)
    
    return chariot_loads

chariot_loads = group_items_into_chariot_loads(ORDER)

print(f"🚛 Chariot Load Distribution:")
for i, load in enumerate(chariot_loads):
    print(f"  Load {i+1} - {load['chariot_name']}: "
          f"{len(load['items'])} item(s), "
          f"{load['total_volume_m3']:.4f}/{load['capacity_m3']:.4f} m³")
print()

# ── Process routes by chariot with timestamps ──────────────────────
START_TIME = datetime(2026, 2, 14, 8, 0, 0)  # Start at 8:00 AM
chariot_finish_times = {c["id"]: START_TIME for c in CHARIOTS}

results = []
print("📦 Processing routes by chariot with timestamps...\n")

for load_idx, load in enumerate(chariot_loads):
    chariot_id = load["chariot_id"]
    chariot_start_time = chariot_finish_times[chariot_id]
    
    print(f"{'='*80}")
    print(f"🚛 Load {load_idx+1} - {load['chariot_name']} (starts at {chariot_start_time.strftime('%H:%M:%S')})")
    print(f"{'='*80}")
    
    load_product_ids = [item["product_id"] for item in load["items"]]
    load_quantities = [1 for _ in load["items"]]  # Each item is already split into units
    
    load_results = opt.find_routes_by_products(load_product_ids, load_quantities)
    
    current_time = chariot_start_time
    
    for i, r in enumerate(load_results):
        item = load["items"][i]
        
        # Add chariot info
        r["_chariot_id"] = chariot_id
        r["_chariot_name"] = load["chariot_name"]
        r["_load_number"] = load_idx + 1
        r["_unit"] = item["unit"]
        r["_total_qty"] = item["total_qty"]
        r["_start_time"] = current_time
        
        # Calculate duration based on total distance and speed
        if "error" not in r:
            total_distance = r.get("total_cost", 0)
            duration_minutes = total_distance / load["speed_m_per_min"]
            r["_duration_minutes"] = duration_minutes
            r["_end_time"] = current_time + timedelta(minutes=duration_minutes)
            
            print(f"  [{i+1}] {r['product_id']} (unit {item['unit']}/{item['total_qty']}) → {r.get('emplacement_code', '?')}")
            print(f"      ⏰ {current_time.strftime('%H:%M:%S')} → {r['_end_time'].strftime('%H:%M:%S')} "
                  f"({duration_minutes:.1f} min, {total_distance} m)")
            
            current_time = r["_end_time"]
        else:
            print(f"  [{i+1}] ⚠ {r['product_id']}: {r['error']}")
            r["_end_time"] = current_time
        
        results.append(r)
    
    # Update chariot finish time
    chariot_finish_times[chariot_id] = current_time
    print(f"  ✓ {load['chariot_name']} completes load at {current_time.strftime('%H:%M:%S')}")
    print()

# Calculate overall completion time
max_finish_time = max(chariot_finish_times.values())
total_time_minutes = (max_finish_time - START_TIME).total_seconds() / 60

print(f"{'='*80}")
print(f"⏱ PARALLEL EXECUTION SUMMARY")
print(f"{'='*80}")
print(f"  Start time:         {START_TIME.strftime('%H:%M:%S')}")
print(f"  End time:           {max_finish_time.strftime('%H:%M:%S')}")
print(f"  Total elapsed:      {total_time_minutes:.1f} minutes")
print()
for chariot in CHARIOTS:
    finish = chariot_finish_times[chariot['id']]
    elapsed = (finish - START_TIME).total_seconds() / 60
    print(f"  {chariot['name']:20s} finished at {finish.strftime('%H:%M:%S')} ({elapsed:.1f} min)")
print(f"{'='*80}")
print()

# ── Summary table with chariot info ────────────────────────────────
HEADER = (
    f"{'#':>3}  {'Product':>8}  {'Unit':>6}  {'Chariot':>18}  {'Load':>5}  "
    f"{'Start':>8}  {'End':>8}  {'Dur(m)':>7}  "
    f"{'Slot':>10}  {'Floor':>5}  {'Total':>6}"
)
SEP = "=" * len(HEADER)

print(SEP)
print("  MULTI-PRODUCT ROUTE SUMMARY (WITH CHARIOT SYSTEM)")
print(SEP)
print(HEADER)
print("-" * len(HEADER))

total_cost = 0
ok = 0
for i, r in enumerate(results, 1):
    pid = r.get("product_id", "?")

    if "error" in r:
        print(f"{i:>3}  {pid:>8}  ⚠ {r['error']}")
        continue

    ok += 1
    src = r["source"]
    slot = r.get("emplacement_code", r.get("source_slot_id", "?"))
    cost = r["total_cost"]
    total_cost += cost
    
    chariot_short = r.get("_chariot_name", "?")[:16]
    unit_str = f"{r.get('_unit', 1)}/{r.get('_total_qty', 1)}"
    start_str = r.get("_start_time", START_TIME).strftime("%H:%M:%S")
    end_str = r.get("_end_time", START_TIME).strftime("%H:%M:%S")
    dur = r.get("_duration_minutes", 0)

    print(
        f"{i:>3}  {pid:>8}  {unit_str:>6}  {chariot_short:>18}  {r.get('_load_number', '?'):>5}  "
        f"{start_str:>8}  {end_str:>8}  {dur:>7.1f}  "
        f"{slot:>10}  {src[0]:>5}  {cost:>6}"
    )

print("-" * len(HEADER))
print(f"  Routed: {ok}/{len(results)}   Total distance: {total_cost} m")
print(f"  Total elapsed time: {total_time_minutes:.1f} minutes (parallel execution)")
print(f"  Chariot loads: {len(chariot_loads)}")
print(SEP)

# ── Create chariot timeline visualization ──────────────────────────
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.dates import DateFormatter, MinuteLocator

fig, ax = plt.subplots(figsize=(16, 8))

# Color map for chariots
chariot_colors = {1: "#e74c3c", 2: "#3498db", 3: "#2ecc71"}

# Plot each route as a horizontal bar
y_positions = {1: 3, 2: 2, 3: 1}
for r in results:
    if "error" in r:
        continue
    
    chariot_id = r.get("_chariot_id", 1)
    start = r.get("_start_time", START_TIME)
    end = r.get("_end_time", START_TIME)
    
    # Draw bar
    y_pos = y_positions[chariot_id]
    width = (end - start).total_seconds() / 60  # in minutes
    
    ax.barh(
        y_pos,
        width,
        left=(start - START_TIME).total_seconds() / 60,
        height=0.6,
        color=chariot_colors[chariot_id],
        alpha=0.7,
        edgecolor="black",
        linewidth=0.5
    )
    
    # Add product label
    pid = r.get("product_id", "?")[:6]
    unit = r.get("_unit", 1)
    mid_time = (start - START_TIME).total_seconds() / 60 + width / 2
    
    if width > 2:  # Only show label if bar is wide enough
        ax.text(
            mid_time, y_pos, f"{pid}\n#{unit}",
            ha="center", va="center", fontsize=7, fontweight="bold",
            color="white"
        )

# Formatting
ax.set_yticks([1, 2, 3])
ax.set_yticklabels([
    f"{CHARIOTS[2]['name']}\n(1 pal)",
    f"{CHARIOTS[1]['name']}\n(1 pal)",
    f"{CHARIOTS[0]['name']}\n(3 pal)"
])
ax.set_xlabel("Time (minutes from start)", fontsize=11, fontweight="bold")
ax.set_ylabel("Chariot", fontsize=11, fontweight="bold")
ax.set_title(
    f"Chariot Timeline - Parallel Execution\n"
    f"Start: {START_TIME.strftime('%H:%M:%S')}  |  "
    f"End: {max_finish_time.strftime('%H:%M:%S')}  |  "
    f"Total: {total_time_minutes:.1f} min  |  "
    f"{len(results)} items across {len(chariot_loads)} loads",
    fontsize=13, fontweight="bold", pad=20
)

# Grid
ax.grid(axis="x", alpha=0.3, linestyle="--")
ax.set_xlim(0, total_time_minutes + 2)

# Legend
legend_patches = [
    mpatches.Patch(color=chariot_colors[c["id"]], label=f"{c['name']} ({c['palette_capacity']} pal)")
    for c in CHARIOTS
]
ax.legend(handles=legend_patches, loc="upper right", fontsize=9)

plt.tight_layout()
plt.savefig("chariot_timeline.png", dpi=150, bbox_inches="tight")
print("\n📊 Saved → chariot_timeline.png")

# ── Visualize all routes on floor grids ────────────────────────────
opt.visualize_multi(results, save_path="multi_route.png")
print("📊 Saved → multi_route.png")