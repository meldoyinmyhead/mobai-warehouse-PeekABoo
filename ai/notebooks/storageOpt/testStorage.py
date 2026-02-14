"""
Multi-product storage assignment test
======================================
Simulates a preparation order: multiple products × quantities.
Slot capacity is capped so products spread across different slots/floors.
All paths are displayed on a 2×2 floor grid.
Simulates 3 chariots working in parallel with timestamps.
"""

import numpy as np
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from storage_assignment import WarehouseOptimizer
from datetime import datetime, timedelta
from collections import Counter

# ─── Define your preparation order here ────────────────────────────
# Format: (product_id, quantity)
# Picked from varied categories & large volumes so they actually fill slots
ORDER = [
    ("31851", 2),   # MODULE          vol≈0.037
    ("39912", 1),   # SPOT            vol≈0.070
    ("35591", 2),   # ICON            vol≈0.041
    ("31985", 1),   # OBERON          vol≈0.041
    ("33028", 1),   # DISPINA         vol≈0.037
    ("31738", 1),   # MONO ACCESS.    vol≈0.038
    ("31520", 2),   # EVOLUTION PLUS  vol≈0.037
    ("36615", 1),   # OCTANS          vol≈0.041
    ("43908", 1),   # MOON            vol≈0.037
    ("31878", 1),   # MODULE          vol≈0.037
]

# ─── Build warehouse ──────────────────────────────────────────────
print("⏳ Building warehouse model …")
optimizer = WarehouseOptimizer()
print(f"✓ Ready — {len(optimizer.product_features)} products, "
      f"{len(optimizer.slot_meta)} storage cells")

# ─── Define Chariot System ────────────────────────────────────────
# 3 chariots with different palette capacities
CHARIOTS = [
    {"id": 1, "palette_capacity": 3, "name": "Large Chariot"},
    {"id": 2, "palette_capacity": 1, "name": "Small Chariot A"},
    {"id": 3, "palette_capacity": 1, "name": "Small Chariot B"},
]

def palette_volume_for_product(product_id: str) -> float:
    """Calculate volume of one palette for a given product."""
    feat = optimizer.product_features.get(str(product_id), {})
    volume_per_piece = feat.get("volume_m3", 0)
    colisage_pal = feat.get("colisage_pal", 1)  # pieces per palette
    if colisage_pal == 0:
        colisage_pal = 1  # avoid division by zero
    return volume_per_piece * colisage_pal

def convert_palette_capacity_to_volume(num_palettes: int, avg_palette_volume: float) -> float:
    """Convert palette capacity to volume capacity."""
    return num_palettes * avg_palette_volume

# Calculate average palette volume across all products in the order
avg_palette_vol = 0.0
for pid, _ in ORDER:
    avg_palette_vol += palette_volume_for_product(pid)
avg_palette_vol /= len(ORDER) if ORDER else 1

print(f"\n📊 Average palette volume in order: {avg_palette_vol:.4f} m³")

# Set volume capacity for each chariot
for chariot in CHARIOTS:
    chariot["volume_capacity_m3"] = convert_palette_capacity_to_volume(
        chariot["palette_capacity"], avg_palette_vol
    )
    print(f"  {chariot['name']} (ID {chariot['id']}): "
          f"{chariot['palette_capacity']} palette(s) = {chariot['volume_capacity_m3']:.4f} m³")

# ── Cap every slot to ~0.05 m³ so each cell holds only 1 product ──
# (Real remaining capacity is ~3333 m³ — way too big for a demo)
CAP_PER_CELL = 0.05
for key in optimizer.slot_meta:
    optimizer.slot_meta[key]["remaining_m3"] = CAP_PER_CELL
    optimizer.slot_meta[key]["total_capacity_m3"] = CAP_PER_CELL
    optimizer.slot_meta[key]["used_m3"] = 0.0

# Re-snapshot so reset() uses capped values
import copy
optimizer._initial_slot_meta = copy.deepcopy(optimizer.slot_meta)
# Rebuild available targets with capped capacity
for floor in optimizer.available_targets:
    for t in optimizer.available_targets[floor]:
        t["available_m3"] = CAP_PER_CELL

print(f"  (slot capacity capped to {CAP_PER_CELL} m³/cell for realistic spread)\n")

# ─── Group items by chariot loads ─────────────────────────────────
def group_items_into_chariot_loads(order_items: list[tuple[str, int]], chariots: list[dict]) -> list[dict]:
    """Group order items into chariot loads based on volume capacity."""
    # Expand order into individual units with volumes
    all_units = []
    for pid, qty in order_items:
        feat = optimizer.product_features.get(str(pid), {})
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
        "items": [],
        "total_volume_m3": 0.0,
    }
    
    for unit in all_units:
        # Check if current item fits in current load
        if current_load["total_volume_m3"] + unit["volume_m3"] > current_load["capacity_m3"]:
            # Save current load and start new one with next chariot
            if current_load["items"]:
                chariot_loads.append(current_load)
            
            # Move to next chariot (cycle through available chariots)
            chariot_idx = (chariot_idx + 1) % len(CHARIOTS)
            current_load = {
                "chariot_id": CHARIOTS[chariot_idx]["id"],
                "chariot_name": CHARIOTS[chariot_idx]["name"],
                "capacity_m3": CHARIOTS[chariot_idx]["volume_capacity_m3"],
                "items": [],
                "total_volume_m3": 0.0,
            }
        
        # Add item to current load
        current_load["items"].append(unit)
        current_load["total_volume_m3"] += unit["volume_m3"]
    
    # Don't forget the last load
    if current_load["items"]:
        chariot_loads.append(current_load)
    
    return chariot_loads

chariot_loads = group_items_into_chariot_loads(ORDER, CHARIOTS)

print(f"\n🚛 Chariot Load Distribution:")
for i, load in enumerate(chariot_loads):
    print(f"  Load {i+1} - {load['chariot_name']}: "
          f"{len(load['items'])} item(s), "
          f"{load['total_volume_m3']:.4f}/{load['capacity_m3']:.4f} m³")

# ─── Simulate parallel chariot operations with timestamps ─────────────────
def simulate_parallel_chariot_operations(chariot_loads: list[dict], start_time: datetime) -> list[dict]:
    """
    Simulate chariots working in parallel, assigning timestamps to each operation.
    Each chariot can work independently and simultaneously.
    
    Time estimates:
    - Pick time per item: 2 minutes (includes travel + pick)
    - Return to base: 3 minutes
    """
    PICK_TIME_PER_ITEM = 2  # minutes
    RETURN_TIME = 3  # minutes
    
    chariot_schedules = {}
    chariot_availability = {}  # Track when each chariot becomes available
    
    # Initialize all chariots as available at start_time
    for chariot in CHARIOTS:
        chariot_availability[chariot['id']] = start_time
    
    for load_idx, load in enumerate(chariot_loads):
        chariot_id = load['chariot_id']
        
        # Chariot starts this load when it becomes available
        load_start = chariot_availability[chariot_id]
        
        # Calculate duration for this load
        num_items = len(load['items'])
        pick_duration = timedelta(minutes=num_items * PICK_TIME_PER_ITEM)
        return_duration = timedelta(minutes=RETURN_TIME)
        total_duration = pick_duration + return_duration
        
        load_end = load_start + total_duration
        
        # Add timestamps to items
        for idx, item in enumerate(load['items']):
            item['start_time'] = load_start + timedelta(minutes=idx * PICK_TIME_PER_ITEM)
            item['end_time'] = item['start_time'] + timedelta(minutes=PICK_TIME_PER_ITEM)
        
        # Store schedule info
        load['start_time'] = load_start
        load['end_time'] = load_end
        load['duration_minutes'] = total_duration.total_seconds() / 60
        
        # Update chariot availability
        chariot_availability[chariot_id] = load_end
        
        # Track in schedule
        if chariot_id not in chariot_schedules:
            chariot_schedules[chariot_id] = []
        chariot_schedules[chariot_id].append(load)
    
    return chariot_loads, chariot_schedules, chariot_availability

# Start simulation at 8:00 AM
START_TIME = datetime.now().replace(hour=8, minute=0, second=0, microsecond=0)
chariot_loads, chariot_schedules, final_availability = simulate_parallel_chariot_operations(
    chariot_loads, START_TIME
)

# Display parallel operation timeline
print(f"\n⏱️  PARALLEL CHARIOT OPERATION TIMELINE (Start: {START_TIME.strftime('%H:%M:%S')})")
print("=" * 100)

for chariot in CHARIOTS:
    chariot_id = chariot['id']
    if chariot_id in chariot_schedules:
        loads = chariot_schedules[chariot_id]
        finish_time = final_availability[chariot_id]
        total_time = (finish_time - START_TIME).total_seconds() / 60
        
        print(f"\n{chariot['name']} (Capacity: {chariot['palette_capacity']} palette(s)):")
        print(f"  Total working time: {total_time:.1f} minutes")
        print(f"  Finish time: {finish_time.strftime('%H:%M:%S')}")
        
        for idx, load in enumerate(loads, 1):
            print(f"    Load {idx}: {load['start_time'].strftime('%H:%M:%S')} → "
                  f"{load['end_time'].strftime('%H:%M:%S')} "
                  f"({load['duration_minutes']:.1f} min, {len(load['items'])} items)")

# Calculate total operation time (when last chariot finishes)
max_finish_time = max(final_availability.values())
total_operation_time = (max_finish_time - START_TIME).total_seconds() / 60

print(f"\n🏁 All chariots complete at: {max_finish_time.strftime('%H:%M:%S')}")
print(f"📊 Total operation time: {total_operation_time:.1f} minutes")
print(f"💡 Parallel efficiency: {len(chariot_loads)} loads completed using {len(CHARIOTS)} chariots")
print("=" * 100)

# ─── Assign products by chariot load (with timestamps) ───────────────────
results: list[dict] = []
skipped: list[tuple[str, str]] = []

print(f"\n📦 Processing assignments with timestamps...")
for load_idx, load in enumerate(chariot_loads):
    print(f"\n  Load {load_idx+1} ({load['chariot_name']}) - "
          f"{load['start_time'].strftime('%H:%M:%S')} to {load['end_time'].strftime('%H:%M:%S')}:")
    for item in load["items"]:
        res = optimizer.find_best_slot(item["product_id"], update_capacity=True)
        if res is None:
            reason = "not found" if item["product_id"] not in optimizer.product_features else "no capacity"
            skipped.append((item["product_id"], reason))
            print(f"    ⚠ [{item['start_time'].strftime('%H:%M:%S')}] "
                  f"Product {item['product_id']} (unit {item['unit']}/{item['total_qty']}): {reason}")
        else:
            res["_unit"] = item["unit"]
            res["_qty"] = item["total_qty"]
            res["_chariot_id"] = load["chariot_id"]
            res["_chariot_name"] = load["chariot_name"]
            res["_load_number"] = load_idx + 1
            res["_start_time"] = item["start_time"]
            res["_end_time"] = item["end_time"]
            results.append(res)
            print(f"    ✓ [{item['start_time'].strftime('%H:%M:%S')}] "
                  f"Product {item['product_id']} (unit {item['unit']}/{item['total_qty']}) → {res['emplacement_code']}")

# ─── Print summary table ──────────────────────────────────────────
total_cost = sum(r["cost"] for r in results) if results else 0
total_dist = sum(r["total_distance"] for r in results if r["total_distance"] >= 0) if results else 0

print()
print("=" * 120)
print("  MULTI-PRODUCT ASSIGNMENT SUMMARY (WITH CHARIOT SYSTEM)")
print("=" * 120)
print(f"  Order lines:        {len(ORDER)}  ({sum(q for _, q in ORDER)} total units)")
print(f"  Chariot loads:      {len(chariot_loads)}")
print(f"  Assigned:           {len(results)}")
if skipped:
    print(f"  Skipped:            {len(skipped)}")
print(f"  Total cost:         {total_cost:.4f}")
print(f"  Total travel dist:  {total_dist} m")

# Floor distribution
floor_dist = Counter(r["floor"] for r in results)
print(f"  Floor distribution: {', '.join(f'Floor {f}: {n}' for f, n in sorted(floor_dist.items()))}")
# Unique slots
unique_slots = set(r["emplacement_code"] for r in results)
print(f"  Unique slots used:  {len(unique_slots)}")

# Chariot distribution
chariot_dist = Counter(r["_chariot_name"] for r in results)
print(f"  Chariot usage:      {', '.join(f'{name}: {n} items' for name, n in chariot_dist.items())}")
print("-" * 130)

header = (f"  {'#':<4} {'Time':<9} {'Product':<10} {'Unit':<6} {'Chariot':<18} {'Load':<6} "
          f"{'ABC':<5} {'Category':<14} {'Floor':<6} {'Slot':<16} {'Cost':<8} "
          f"{'Vol':<8}")
print(header)
print("-" * 130)

unique_pids = list(dict.fromkeys(r["product_id"] for r in results))
pid_color_idx = {pid: i for i, pid in enumerate(unique_pids)}

for i, r in enumerate(results):
    feat = optimizer.product_features.get(r["product_id"], {})
    cat = str(feat.get("categorie", "?"))[:12]
    chariot_short = r["_chariot_name"][:16]
    time_str = r["_start_time"].strftime('%H:%M:%S')
    print(
        f"  {i+1:<4} {time_str:<9} {r['product_id']:<10} "
        f"{r['_unit']}/{r['_qty']:<3} "
        f"{chariot_short:<18} {r['_load_number']:<6} "
        f"{r['abc_class']:<5} {cat:<14} "
        f"{r['floor']:<6} {r['emplacement_code']:<16} "
        f"{r['cost']:<8.4f} "
        f"{r['product_volume_m3']:<8.4f}"
    )

if skipped:
    print("-" * 130)
    for pid, reason in skipped:
        print(f"  ⚠  {pid}: {reason}")
print("=" * 130)

# ─── Per-product journey details with timestamps ────────────────────────
print(f"\n{'='*80}")
print(f"  DETAILED JOURNEY BY CHARIOT LOAD (WITH TIMESTAMPS)")
print(f"{'='*80}")
current_load = None
for i, r in enumerate(results):
    if current_load != r['_load_number']:
        current_load = r['_load_number']
        # Find load info for timestamps
        load_info = next((l for l in chariot_loads if l['chariot_id'] == r['_chariot_id'] 
                         and chariot_loads.index(l) == current_load - 1), None)
        if load_info:
            print(f"\n🚛 Load {current_load} - {r['_chariot_name']} "
                  f"[{load_info['start_time'].strftime('%H:%M:%S')} → "
                  f"{load_info['end_time'].strftime('%H:%M:%S')}]:")
        else:
            print(f"\n🚛 Load {current_load} - {r['_chariot_name']}:")
    
    feat = optimizer.product_features.get(r["product_id"], {})
    print(f"  [{i+1}] ⏰ {r['_start_time'].strftime('%H:%M:%S')} - {r['product_id']} ({feat.get('categorie','?')}) "
          f"[{r['abc_class']}] unit {r['_unit']}/{r['_qty']}")
    print(f"      Ground(0) ─elev({r['elevator_cost']}m)─▶ "
          f"Floor {r['floor']} ─walk({r['walk_distance']}m)─▶ "
          f"{r['emplacement_code']}  │ Total: {r['total_distance']}m  │  Vol: {r['product_volume_m3']:.4f} m³")
    if r["path"]:
        print(f"      Path: {' → '.join(f'({row},{col})' for row, col in r['path'])}")

# ═══════════════════════════════════════════════════════════════════
# VISUALIZATION — 2×2 grid showing all 4 floors, paths overlaid
# ═══════════════════════════════════════════════════════════════════

COLORS = [
    "#e6194b", "#3cb44b", "#4363d8", "#f58231", "#911eb4",
    "#42d4f4", "#f032e6", "#bfef45", "#fabed4", "#469990",
    "#dcbeff", "#9A6324", "#800000", "#aaffc3",
]

fig, axes = plt.subplots(2, 2, figsize=(24, 18))
fig.suptitle(
    f"Multi-Product Storage Assignment (Chariot System)\n"
    f"{len(results)} units  ·  {len(chariot_loads)} chariot loads  ·  {len(unique_slots)} slots  ·  "
    f"Total distance: {total_dist} m  ·  Total cost: {total_cost:.4f}",
    fontsize=15, fontweight="bold",
)

for idx, floor in enumerate([1, 2, 3, 4]):
    ax = axes[idx // 2, idx % 2]
    t = optimizer.floor_matrices[floor]["type"]

    # Floor layout
    ax.imshow(t, cmap=optimizer.CMAP, vmin=0, vmax=4,
              interpolation="nearest", alpha=0.45)

    # Mark chariot positions
    for cr, cc in optimizer.chariot_positions[floor]:
        ax.plot(cc, cr, "rs", markersize=8, markeredgecolor="black", markeredgewidth=1)

    # Draw paths for products on this floor
    floor_results = [r for r in results if r["floor"] == floor]
    legend_entries = {}
    label_positions = []  # track label positions to avoid overlap

    for r_idx, r in enumerate(floor_results):
        pid = r["product_id"]
        ci = pid_color_idx[pid] % len(COLORS)
        color = COLORS[ci]
        path = r["path"]

        if path:
            pr = [p[0] for p in path]
            pc = [p[1] for p in path]
            # Slight offset for overlapping paths (jitter by product index)
            jitter = (r_idx - len(floor_results) / 2) * 0.08
            pc_j = [p + jitter for p in pc]
            pr_j = [p + jitter for p in pr]

            ax.plot(pc_j, pr_j, "o-", color=color, linewidth=2.5,
                    markersize=4, markeredgecolor="black",
                    markeredgewidth=0.5, alpha=0.85, zorder=3)
            # Chariot exit (star)
            ax.plot(pc_j[0], pr_j[0], "*", color=color, markersize=16,
                    markeredgecolor="black", markeredgewidth=1, zorder=4)
            # Target slot (triangle)
            ax.plot(pc_j[-1], pr_j[-1], "^", color=color, markersize=12,
                    markeredgecolor="black", markeredgewidth=1.5, zorder=4)

            # Smart label placement — alternate offset direction
            feat = optimizer.product_features.get(pid, {})
            cat_short = str(feat.get("categorie", ""))[:10]
            chariot_id = r.get("_chariot_id", "?")
            offset_x = 10 if (r_idx % 2 == 0) else -60
            offset_y = -12 - (r_idx % 3) * 10

            ax.annotate(
                f"{r['emplacement_code']} [C{chariot_id}]",
                xy=(pc[-1], pr[-1]),
                xytext=(offset_x, offset_y), textcoords="offset points",
                fontsize=7, fontweight="bold", color=color,
                bbox=dict(boxstyle="round,pad=0.15", fc="white", ec=color, alpha=0.9),
                arrowprops=dict(arrowstyle="-", color=color, lw=0.8),
                zorder=5,
            )

        # Legend entry (one per product)
        if pid not in legend_entries:
            feat = optimizer.product_features.get(pid, {})
            chariot_name_short = r.get("_chariot_name", "Unknown")[:10]
            label = f"{pid} [{r['abc_class']}] {feat.get('categorie', '')} ({chariot_name_short})"
            legend_entries[pid] = mpatches.Patch(color=color, label=label)

    # Floor-level stats
    if floor_results:
        fc = sum(r["cost"] for r in floor_results)
        fd = sum(r["total_distance"] for r in floor_results if r["total_distance"] >= 0)
        slots_here = len(set(r["emplacement_code"] for r in floor_results))
        ax.set_title(
            f"Floor {floor}  —  {len(floor_results)} units in {slots_here} slot(s)  │  "
            f"cost: {fc:.3f}  │  dist: {fd} m",
            fontsize=11, fontweight="bold",
        )
    else:
        ax.set_title(f"Floor {floor}  —  no assignments", fontsize=11, fontstyle="italic")

    # Layout legend (compact)
    layout_handles = [
        mpatches.Patch(facecolor="white", label="Aisle", edgecolor="gray", linewidth=0.5),
        mpatches.Patch(color="lightblue", label="Storage"),
        mpatches.Patch(color="lightgreen", label="Elevator"),
        mpatches.Patch(color="red", label="Chariot"),
    ]
    all_handles = layout_handles + list(legend_entries.values())
    ax.legend(handles=all_handles, loc="upper right", fontsize=6.5,
              framealpha=0.9, ncol=1)

    ax.set_xlabel("Column", fontsize=9)
    ax.set_ylabel("Row", fontsize=9)
    ax.set_xticks(np.arange(-0.5, t.shape[1], 1), minor=True)
    ax.set_yticks(np.arange(-0.5, t.shape[0], 1), minor=True)
    ax.grid(which="minor", color="gray", linestyle="-", linewidth=0.15, alpha=0.25)

plt.tight_layout(rect=[0, 0, 1, 0.94])
plt.savefig("multi_assignment.png", dpi=150, bbox_inches="tight")
print(f"\n📊 Saved → multi_assignment.png")
plt.show()

# ═══════════════════════════════════════════════════════════════════
# GANTT CHART — Parallel Chariot Timeline
# ═══════════════════════════════════════════════════════════════════

fig_gantt, ax_gantt = plt.subplots(figsize=(16, 6))
fig_gantt.suptitle(
    f"Parallel Chariot Operation Timeline\n"
    f"Start: {START_TIME.strftime('%H:%M:%S')} | "
    f"Finish: {max_finish_time.strftime('%H:%M:%S')} | "
    f"Total: {total_operation_time:.1f} min",
    fontsize=14, fontweight="bold"
)

# Define colors for each chariot
chariot_colors = {
    1: "#3cb44b",  # Green
    2: "#4363d8",  # Blue
    3: "#e6194b",  # Red
}

y_positions = {}
for idx, chariot in enumerate(CHARIOTS):
    y_positions[chariot['id']] = len(CHARIOTS) - idx

for chariot in CHARIOTS:
    chariot_id = chariot['id']
    if chariot_id in chariot_schedules:
        y_pos = y_positions[chariot_id]
        
        for load in chariot_schedules[chariot_id]:
            start_minutes = (load['start_time'] - START_TIME).total_seconds() / 60
            duration = load['duration_minutes']
            
            # Draw load bar
            ax_gantt.barh(
                y_pos, duration, left=start_minutes,
                height=0.6, color=chariot_colors.get(chariot_id, 'gray'),
                alpha=0.8, edgecolor='black', linewidth=1.5
            )
            
            # Add load label
            label_text = f"Load {chariot_loads.index(load) + 1}\n{len(load['items'])} items"
            ax_gantt.text(
                start_minutes + duration/2, y_pos,
                label_text,
                ha='center', va='center',
                fontsize=8, fontweight='bold', color='white'
            )
            
            # Add time labels
            ax_gantt.text(
                start_minutes, y_pos - 0.45,
                load['start_time'].strftime('%H:%M'),
                ha='center', va='top', fontsize=7, color='gray'
            )
            ax_gantt.text(
                start_minutes + duration, y_pos - 0.45,
                load['end_time'].strftime('%H:%M'),
                ha='center', va='top', fontsize=7, color='gray'
            )

# Customize axes
ax_gantt.set_yticks(list(y_positions.values()))
ax_gantt.set_yticklabels([f"{c['name']}\n({c['palette_capacity']} pal)" for c in CHARIOTS])
ax_gantt.set_xlabel("Time (minutes from start)", fontsize=11, fontweight='bold')
ax_gantt.set_ylabel("Chariot", fontsize=11, fontweight='bold')
ax_gantt.set_xlim(0, total_operation_time + 5)
ax_gantt.set_ylim(0.5, len(CHARIOTS) + 0.5)
ax_gantt.grid(axis='x', alpha=0.3, linestyle='--')
ax_gantt.axvline(x=total_operation_time, color='red', linestyle='--', linewidth=2, label='All Complete')

# Add legend showing parallel execution
legend_elements = [
    mpatches.Patch(color=chariot_colors[1], label=CHARIOTS[0]['name']),
    mpatches.Patch(color=chariot_colors[2], label=CHARIOTS[1]['name']),
    mpatches.Patch(color=chariot_colors[3], label=CHARIOTS[2]['name']),
]
ax_gantt.legend(handles=legend_elements, loc='upper right', fontsize=9)

plt.tight_layout()
plt.savefig("chariot_timeline.png", dpi=150, bbox_inches="tight")
print(f"📊 Saved → chariot_timeline.png")
plt.show()

print(f"\n✅ Complete! 3 chariots working in parallel completed all tasks in {total_operation_time:.1f} minutes.")