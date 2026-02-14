from route_optimizer import RouteOptimizer
opt = RouteOptimizer()

shelves = [t for t in opt.all_targets if t["type"] == "shelf"]
exh = [t for t in opt.all_targets if t["type"] == "exhibition"]

print(f"Total shelf targets on ground floor: {len(shelves)}")
print(f"Total exhibition targets: {len(exh)}")
print(f"Total all targets: {len(opt.all_targets)}")
print()

print("All shelf targets:")
for s in shelves:
    print(f"  {s['label']:>12}  cells={s['shelf_cells']}  access={s['access_points']}")

print()
print("Chariot positions on ground floor:")
for cr, cc, _ in opt.dist_from_chariot[0]:
    print(f"  chariot at ({cr}, {cc})")

# Check cost from a product to every target
print()
print("Cost from product 31725 (floor1, row8, col42) to EACH shelf target:")
for tgt in shelves:
    cost, ch_s, ch_g, ap = opt._full_path_cost(1, 8, 42, tgt["access_points"])
    print(f"  → {tgt['label']:>12}  cost={cost}  via chariot_src={ch_s} chariot_gf={ch_g} access={ap}")
