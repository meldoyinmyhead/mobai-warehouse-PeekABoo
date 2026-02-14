"""
Shelf-filling simulation
=========================
Shows WHY all products currently land on shelf 0A-01-01:
the optimizer always picks the *nearest* shelf on the ground floor.

This simulation adds a **capacity per shelf** (e.g. 3 products each).
Once a shelf is full, the next product overflows to the second-closest
shelf, and so on.  You can watch the shelves fill up in real time.

At the end, a summary + a heat-map of which shelves received products
is printed & saved.
"""

import numpy as np
import matplotlib.pyplot as plt
from matplotlib.colors import ListedColormap
import matplotlib.patches as mpatches
from route_optimizer import RouteOptimizer

# ── CONFIG ──────────────────────────────────────────────────────────
SHELF_CAPACITY = 3          # max products per ground-floor shelf
NUM_PRODUCTS   = 40         # how many products to route

# Product IDs pulled from inventory (all verified to exist)
ALL_PRODUCTS = [
    "31496", "31725", "31554", "35585", "34015", "31565", "31730",
    "34016", "35574", "31461", "31363", "31367", "31437", "31449",
    "31462", "31463", "31475", "31494", "31528", "31531", "31532",
    "31543", "31548", "31549", "31551", "31552", "31556", "31557",
    "34013", "34014", "34017", "34018", "35580", "35584", "35586",
    "37145", "37146", "31756", "31484", "31473",
]
PRODUCT_IDS = ALL_PRODUCTS[:NUM_PRODUCTS]

# ── BUILD OPTIMIZER ─────────────────────────────────────────────────
print("⏳ Building warehouse model …")
opt = RouteOptimizer()
print("✓ Ready\n")

# ── STATE — track how many items each shelf has received ────────────
shelf_fill: dict[str, int]   = {}   # shelf_label → count
shelf_items: dict[str, list] = {}   # shelf_label → [product_ids]

# We'll collect full results for the final visualization
assignments: list[dict] = []


def find_route_with_capacity(opt, product_id, shelf_fill, cap):
    """
    Route a product to the best ground-floor shelf that still has room.
    Iterates over ALL shelf targets sorted by cost and picks the first
    one with remaining capacity.
    """
    # Get all candidate source slots for this product
    candidates = opt._find_product_locations(str(product_id), 1)
    if not candidates:
        return {"product_id": product_id, "error": "not in inventory"}

    # For each candidate source slot, compute cost to EVERY shelf target
    shelf_targets = [t for t in opt.all_targets if t["type"] == "shelf"]

    scored = []  # (total_cost, src_cand, target)
    for cand in candidates:
        fl, r, c = cand["floor"], cand["row"], cand["col"]
        for tgt in shelf_targets:
            cost, ch_s, ch_g, ap = opt._full_path_cost(
                fl, r, c, tgt["access_points"]
            )
            if cost < np.inf:
                scored.append({
                    "cost": cost,
                    "cand": cand,
                    "target": tgt,
                    "ch_s": ch_s,
                    "ch_g": ch_g,
                    "ap": ap,
                })

    # Sort by cost — cheapest first
    scored.sort(key=lambda x: x["cost"])

    # Pick the first shelf that has room
    for s in scored:
        label = s["target"]["label"]
        current = shelf_fill.get(label, 0)
        if current < cap:
            # This shelf has room — route here
            fl = s["cand"]["floor"]
            r  = s["cand"]["row"]
            c  = s["cand"]["col"]
            route = opt.find_route(fl, r, c, target_type="shelf")

            # Override target to be this specific shelf (not the global best)
            # We need to reconstruct the path to THIS shelf's access point
            result = opt._reconstruct_full_path(fl, r, c, s["target"]["access_points"])
            if result is None:
                continue

            return {
                "product_id": product_id,
                "source": (fl, r, c),
                "source_slot_id": opt._get_slot_id(fl, r, c),
                "emplacement_code": s["cand"]["emplacement_code"],
                "target_slot_id": label,
                "target_type": "shelf",
                "target_shelf_cells": s["target"].get("shelf_cells", []),
                "access_point": result["best_access_point"],
                "total_cost": result["total_cost"],
                "leg1_path": result["leg1_path"],
                "leg2_transit": result["leg2_floors"],
                "leg2_cost": fl * opt.CHARIOT_TRANSIT_COST,
                "leg3_path": result["leg3_path"],
                "src_chariot": result["src_chariot"],
                "gf_chariot": result["gf_chariot"],
            }

    return {"product_id": product_id, "error": "all reachable shelves are full"}


# ── RUN SIMULATION ─────────────────────────────────────────────────
print(f"Simulating {NUM_PRODUCTS} products, shelf capacity = {SHELF_CAPACITY}\n")
print(f"{'#':>3}  {'Product':>8}  {'Shelf':>12}  {'Fill':>7}  {'Cost':>5}  {'Floor':>5}  Status")
print("-" * 75)

for i, pid in enumerate(PRODUCT_IDS, 1):
    result = find_route_with_capacity(opt, pid, shelf_fill, SHELF_CAPACITY)

    if "error" in result:
        print(f"{i:>3}  {pid:>8}  {'—':>12}  {'—':>7}  {'—':>5}  {'—':>5}  ⚠ {result['error']}")
        assignments.append(result)
        continue

    shelf_label = result["target_slot_id"]
    shelf_fill[shelf_label] = shelf_fill.get(shelf_label, 0) + 1
    if shelf_label not in shelf_items:
        shelf_items[shelf_label] = []
    shelf_items[shelf_label].append(pid)

    fill_str = f"{shelf_fill[shelf_label]}/{SHELF_CAPACITY}"
    full_tag = " ★ FULL" if shelf_fill[shelf_label] >= SHELF_CAPACITY else ""
    src_floor = result["source"][0]

    print(
        f"{i:>3}  {pid:>8}  {shelf_label:>12}  {fill_str:>7}  "
        f"{result['total_cost']:>5}  {src_floor:>5}{full_tag}"
    )
    assignments.append(result)

# ── SUMMARY ─────────────────────────────────────────────────────────
print()
print("=" * 75)
print("  SHELF OCCUPANCY AFTER SIMULATION")
print("=" * 75)
for shelf_label in sorted(shelf_fill.keys()):
    cnt = shelf_fill[shelf_label]
    items = shelf_items[shelf_label]
    bar = "█" * cnt + "░" * (SHELF_CAPACITY - cnt)
    print(f"  {shelf_label:>12}  [{bar}]  {cnt}/{SHELF_CAPACITY}  products: {items}")

ok = sum(1 for a in assignments if "error" not in a)
used_shelves = len(shelf_fill)
total_cost = sum(a.get("total_cost", 0) for a in assignments if "error" not in a)
print(f"\n  Routed: {ok}/{NUM_PRODUCTS}  |  Shelves used: {used_shelves}  |  Total cost: {total_cost}")
print("=" * 75)

# ── VISUALIZATION — ground-floor heat map of shelf usage ────────────
gf_type = opt.floor_matrices[0]["type"]
rows_gf, cols_gf = gf_type.shape

# Build a heat-map layer: how many products each shelf cell received
heat = np.zeros((rows_gf, cols_gf), dtype=float)
for shelf_label, cnt in shelf_fill.items():
    if shelf_label in opt.shelf_targets:
        for (sr, sc) in opt.shelf_targets[shelf_label]["cells"]:
            heat[sr, sc] = cnt

# Ground-floor base image
gf_colors = [
    "#FFFFFF",   # 0 aisle
    "#D2B48C",   # 1 shelf (tan)
    "#FFD700",   # 2 elevator
    "#00BFFF",   # 3 chariot
    "#333333",   # 4 obstacle
    "#90EE90",   # 5 VRAC
    "#FF69B4",   # 6 exhibition
    "#FF4500",   # 7 bureau
]
gf_cmap = ListedColormap(gf_colors)

fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(18, 8))

# Left: ground floor layout with route endpoints
ax1.imshow(gf_type, cmap=gf_cmap, origin="upper", vmin=0, vmax=7)
ax1.set_title("Ground Floor — Product Drop-off Points", fontsize=12)

# Overlay leg3 paths for every assigned product
colors_cycle = plt.cm.tab20(np.linspace(0, 1, 20))
for idx, a in enumerate(assignments):
    if "error" in a:
        continue
    leg3 = a["leg3_path"]
    if leg3:
        rs = [p[1] for p in leg3]
        cs = [p[2] for p in leg3]
        c = colors_cycle[idx % 20]
        ax1.plot(cs, rs, "-o", color=c, markersize=3, linewidth=1.5, alpha=0.7)
        ax1.plot(cs[-1], rs[-1], "*", color=c, markersize=10)

# Legend patches
patches = [
    mpatches.Patch(color=c, label=l) for c, l in zip(
        gf_colors, ["Aisle", "Shelf", "Elevator", "Chariot",
                     "Obstacle", "VRAC", "Exhibition", "Bureau"]
    )
]
ax1.legend(handles=patches, fontsize=7, loc="lower right")

# Right: heat map of shelf occupancy
heat_display = np.where(heat > 0, heat, np.nan)
ax2.imshow(gf_type, cmap=gf_cmap, origin="upper", vmin=0, vmax=7, alpha=0.3)
im = ax2.imshow(heat_display, cmap="YlOrRd", origin="upper",
                vmin=0, vmax=SHELF_CAPACITY, alpha=0.9)
ax2.set_title("Shelf Occupancy Heat Map", fontsize=12)
cbar = fig.colorbar(im, ax=ax2, shrink=0.6, label="Products stored")

# Annotate filled shelves
for shelf_label, cnt in shelf_fill.items():
    if shelf_label in opt.shelf_targets:
        cells = opt.shelf_targets[shelf_label]["cells"]
        r, c = cells[0]
        ax2.text(c, r, f"{cnt}", ha="center", va="center",
                 fontsize=7, color="black", fontweight="bold")

plt.suptitle(
    f"Shelf Fill Simulation — {NUM_PRODUCTS} products, "
    f"capacity {SHELF_CAPACITY}/shelf, {used_shelves} shelves used",
    fontsize=14
)
plt.tight_layout()
fig.savefig("shelf_fill_simulation.png", dpi=150, bbox_inches="tight")
print("\n📊 Saved → shelf_fill_simulation.png")
