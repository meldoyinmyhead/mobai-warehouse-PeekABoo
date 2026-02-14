"""
Multi-product route test — finds the optimal path from each product's
storage slot (floors 1–4) down to the ground floor, prints a summary
table, and visualizes every route.
"""

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

# ── Find best route for every product ──────────────────────────────
results = opt.find_routes_by_products(product_ids, quantities)

# ── Print individual results ───────────────────────────────────────
for r in results:
    opt.print_result(r)
    print()

# ── Summary table ──────────────────────────────────────────────────
HEADER = (
    f"{'#':>3}  {'Product':>8}  {'Qty':>3}  {'Slot':>10}  "
    f"{'Floor':>5}  {'Source':>14}  {'Target':>12}  "
    f"{'Elev':>5}  {'Walk1':>5}  {'Walk3':>5}  {'Total':>6}"
)
SEP = "=" * len(HEADER)

print(SEP)
print("  MULTI-PRODUCT ROUTE SUMMARY")
print(SEP)
print(HEADER)
print("-" * len(HEADER))

total_cost = 0
ok = 0
for i, r in enumerate(results, 1):
    pid = r.get("product_id", "?")
    qty = r.get("requested_qty", "?")

    if "error" in r:
        print(f"{i:>3}  {pid:>8}  {qty:>3}  ⚠ {r['error']}")
        continue

    ok += 1
    src = r["source"]
    slot = r.get("emplacement_code", r.get("source_slot_id", "?"))
    tgt  = r.get("target_slot_id", "?")
    leg1 = len(r["leg1_path"])
    leg2 = r["leg2_cost"]
    leg3 = len(r["leg3_path"])
    cost = r["total_cost"]
    total_cost += cost

    print(
        f"{i:>3}  {pid:>8}  {qty:>3}  {slot:>10}  "
        f"{src[0]:>5}  ({src[1]:>3},{src[2]:>3})      "
        f"{tgt:>12}  {leg2:>5}  {leg1:>5}  {leg3:>5}  {cost:>6}"
    )

print("-" * len(HEADER))
print(f"  Routed: {ok}/{len(results)}   Total cost: {total_cost}")
print(SEP)

# ── Visualize all routes ───────────────────────────────────────────
opt.visualize_multi(results, save_path="multi_route.png")
print("📊 Saved → multi_route.png")