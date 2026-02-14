"""
Multi-product storage assignment test
======================================
Simulates a preparation order: multiple products × quantities.
Slot capacity is capped so products spread across different slots/floors.
All paths are displayed on a 2×2 floor grid.
"""

import numpy as np
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from storage_assignment import WarehouseOptimizer

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

# ─── Assign products ──────────────────────────────────────────────
results: list[dict] = []
skipped: list[tuple[str, str]] = []

for pid, qty in ORDER:
    for unit in range(1, qty + 1):
        res = optimizer.find_best_slot(str(pid), update_capacity=True)
        if res is None:
            reason = "not found" if str(pid) not in optimizer.product_features else "no capacity"
            skipped.append((str(pid), reason))
            print(f"  ⚠ Product {pid} (unit {unit}/{qty}): {reason}")
        else:
            res["_unit"] = unit
            res["_qty"] = qty
            results.append(res)

# ─── Print summary table ──────────────────────────────────────────
total_cost = sum(r["cost"] for r in results) if results else 0
total_dist = sum(r["total_distance"] for r in results if r["total_distance"] >= 0) if results else 0

print()
print("=" * 105)
print("  MULTI-PRODUCT ASSIGNMENT SUMMARY")
print("=" * 105)
print(f"  Order lines:        {len(ORDER)}  ({sum(q for _, q in ORDER)} total units)")
print(f"  Assigned:           {len(results)}")
if skipped:
    print(f"  Skipped:            {len(skipped)}")
print(f"  Total cost:         {total_cost:.4f}")
print(f"  Total travel dist:  {total_dist} m")

# Floor distribution
from collections import Counter
floor_dist = Counter(r["floor"] for r in results)
print(f"  Floor distribution: {', '.join(f'Floor {f}: {n}' for f, n in sorted(floor_dist.items()))}")
# Unique slots
unique_slots = set(r["emplacement_code"] for r in results)
print(f"  Unique slots used:  {len(unique_slots)}")
print("-" * 105)

header = (f"  {'#':<4} {'Product':<10} {'Unit':<6} {'ABC':<5} {'Category':<18} "
          f"{'Floor':<6} {'Slot':<16} {'Cost':<8} "
          f"{'Elev':<6} {'Walk':<6} {'Total':<7} {'Vol':<8}")
print(header)
print("-" * 105)

unique_pids = list(dict.fromkeys(r["product_id"] for r in results))
pid_color_idx = {pid: i for i, pid in enumerate(unique_pids)}

for i, r in enumerate(results):
    feat = optimizer.product_features.get(r["product_id"], {})
    cat = str(feat.get("categorie", "?"))[:16]
    print(
        f"  {i+1:<4} {r['product_id']:<10} "
        f"{r['_unit']}/{r['_qty']:<3} "
        f"{r['abc_class']:<5} {cat:<18} "
        f"{r['floor']:<6} {r['emplacement_code']:<16} "
        f"{r['cost']:<8.4f} "
        f"{r['elevator_cost']:<6} "
        f"{r['walk_distance']:<6} "
        f"{r['total_distance']:<7} "
        f"{r['product_volume_m3']:<8.4f}"
    )

if skipped:
    print("-" * 105)
    for pid, reason in skipped:
        print(f"  ⚠  {pid}: {reason}")
print("=" * 105)

# ─── Per-product journey details ──────────────────────────────────
for i, r in enumerate(results):
    feat = optimizer.product_features.get(r["product_id"], {})
    print(f"\n  [{i+1}] {r['product_id']} ({feat.get('categorie','?')}) "
          f"[{r['abc_class']}] unit {r['_unit']}/{r['_qty']}")
    print(f"      Ground(0) ─elev({r['elevator_cost']}m)─▶ "
          f"Floor {r['floor']} ─walk({r['walk_distance']}m)─▶ "
          f"{r['emplacement_code']}  │ Total: {r['total_distance']}m")
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
    f"Multi-Product Storage Assignment\n"
    f"{len(results)} units  ·  {len(unique_slots)} slots  ·  "
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
            offset_x = 10 if (r_idx % 2 == 0) else -60
            offset_y = -12 - (r_idx % 3) * 10

            ax.annotate(
                f"{r['emplacement_code']}",
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
            label = f"{pid} [{r['abc_class']}] {feat.get('categorie', '')}"
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