"""
Unified Warehouse Inference Script
====================================
Reads a CSV of orders (Date, Product, Flow Type, Quantity) and:
  - Ingoing  -> assigns optimal storage slots  (storageOpt / WarehouseOptimizer)
  - Outgoing -> finds optimal picking routes    (routeOpt  / RouteOptimizer)

Outputs a structured CSV:  Product, Action, Location, Route, Reason

Usage:
    python inference.py                          # uses default test_orders.csv
    python inference.py --input my_orders.csv    # custom input
    python inference.py --input orders.csv --output results.csv
"""

import sys
import copy
import argparse
import pandas as pd
from pathlib import Path
from datetime import datetime

# ── Directory setup ─────────────────────────────────────────────────
_THIS_DIR = Path(__file__).resolve().parent
_ROUTE_OPT_DIR = _THIS_DIR / "routeOpt"
_STORAGE_OPT_DIR = _THIS_DIR / "storageOpt"

# Add both module directories to sys.path so imports work
sys.path.insert(0, str(_ROUTE_OPT_DIR))
sys.path.insert(0, str(_STORAGE_OPT_DIR))

from route_optimizer import RouteOptimizer
from storage_assignment import WarehouseOptimizer


# =====================================================================
# HELPERS
# =====================================================================

def _get_slot_name(optimizer, floor: int, row: int, col: int) -> str:
    """Look up the slot name at (floor, row, col) from the optimizer's slot matrix."""
    try:
        s = optimizer.floor_matrices[floor]["slots"]
        if 0 <= row < s.shape[0] and 0 <= col < s.shape[1] and s[row, col] is not None:
            return str(s[row, col])
    except (KeyError, IndexError, AttributeError):
        pass
    return None


def _resolve_point(optimizer, floor: int, row: int, col: int) -> str:
    """Resolve a grid point to its slot name, or fall back to (row,col)."""
    name = _get_slot_name(optimizer, floor, row, col)
    return name if name else f"({row},{col})"


def _format_path_slots(optimizer, floor: int, path_list: list) -> str:
    """Format a path as slot names. Consecutive cells in the same slot are collapsed."""
    if not path_list:
        return ""
    # Resolve each cell to a label, collapsing consecutive duplicates
    labels = []
    prev = None
    for p in path_list:
        r, c = (p[1], p[2]) if len(p) == 3 else (p[0], p[1])
        fl = p[0] if len(p) == 3 else floor
        name = _get_slot_name(optimizer, fl, r, c)
        label = name if name else f"({r},{c})"
        if label != prev:
            labels.append(label)
            prev = label
    return " > ".join(labels)


def build_route_description_outgoing(result: dict, optimizer) -> str:
    """
    Build a detailed route for OUTGOING (picking) orders.

    Uses slot names instead of (row,col) tuples:
      Slot(Floor F) --walk(Xm)--> Chariot --elevator(Ym; F floors)-->
      GF Chariot --walk(Zm)--> Target shelf | Total: Tm | Leg1[...] | Leg3[...]
    """
    src = result.get("source", (0, 0, 0))
    floor = src[0]
    slot_code = result.get("emplacement_code", result.get("source_slot_id", "?"))
    target_shelf = result.get("target_slot_id", "Expedition")
    total_cost = result.get("total_cost", 0)

    # Leg 1: source slot -> chariot on upper floor
    leg1 = result.get("leg1_path", [])
    leg1_dist = len(leg1) - 1 if leg1 else 0
    src_chariot = result.get("src_chariot", None)
    src_ch_name = _resolve_point(optimizer, floor, src_chariot[0], src_chariot[1]) if src_chariot else "?"

    # Leg 2: chariot elevator transit
    leg2_cost = result.get("leg2_cost", floor * 10)

    # Leg 3: ground floor chariot -> target shelf access point
    leg3 = result.get("leg3_path", [])
    leg3_dist = len(leg3) - 1 if leg3 else 0
    gf_chariot = result.get("gf_chariot", None)
    gf_ch_name = _resolve_point(optimizer, 0, gf_chariot[0], gf_chariot[1]) if gf_chariot else "?"
    access_pt = result.get("access_point", None)
    access_name = _resolve_point(optimizer, 0, access_pt[0], access_pt[1]) if access_pt else "?"

    # Build the path with slot names
    leg1_path_str = _format_path_slots(optimizer, floor, leg1)
    leg3_path_str = _format_path_slots(optimizer, 0, leg3)

    route = (
        f"{slot_code}(Floor {floor}) "
        f"--walk({leg1_dist}m)--> Chariot@{src_ch_name} "
        f"--elevator({leg2_cost}m; {floor} floors)--> "
        f"GF Chariot@{gf_ch_name} "
        f"--walk({leg3_dist}m)--> {target_shelf}@{access_name} "
        f"| Total: {total_cost}m "
        f"| Leg1[{leg1_path_str}] "
        f"| Leg3[{leg3_path_str}]"
    )

    return route


def build_route_description_ingoing(result: dict, optimizer) -> str:
    """
    Build a detailed route for INGOING (storage) orders.

    Uses slot names instead of (row,col) tuples:
      Reception(GF) --elevator(Xm)--> Floor F --walk(Ym)--> Slot | Total: Zm | Path[...]
    """
    floor = result.get("floor", 0)
    slot_code = result.get("emplacement_code", "?")
    walk_dist = result.get("walk_distance", -1)
    elevator_cost = result.get("elevator_cost", 0)
    total_dist = result.get("total_distance", -1)
    path = result.get("path", [])
    position = result.get("position", (0, 0))

    # Resolve the target position to a slot name
    target_name = _resolve_point(optimizer, floor, position[0], position[1])

    # Format the walking path with slot names
    path_str = _format_path_slots(optimizer, floor, path) if path else "direct"

    route = (
        f"Reception(GF) "
        f"--elevator({elevator_cost}m)--> Floor {floor} "
        f"--walk({walk_dist}m)--> {slot_code}@{target_name} "
        f"| Total: {total_dist}m "
        f"| Path[{path_str}]"
    )

    return route


def build_reason_outgoing(result: dict) -> str:
    """Build reason for outgoing picking route."""
    cost = result.get("total_cost", 0)
    candidates = result.get("candidate_slots", 1)
    avail_qty = result.get("available_qty", "?")
    src = result.get("source", (0, 0, 0))
    floor = src[0]
    return (
        f"Min distance: {cost}m from {candidates} candidate slot(s); "
        f"floor {floor}; {avail_qty} units available"
    )


def build_reason_ingoing(result: dict) -> str:
    """Build reason for ingoing storage assignment."""
    abc = result.get("abc_class", "?")
    cost = result.get("cost", 0)
    remaining = result.get("remaining_capacity_m3", 0)
    vol = result.get("product_volume_m3", 0)
    floor = result.get("floor", 0)
    return (
        f"Optimal cost: {cost:.4f}; ABC class {abc}; "
        f"floor {floor}; vol={vol:.6f}m3; "
        f"remaining capacity={remaining:.4f}m3"
    )


# =====================================================================
# MAIN INFERENCE
# =====================================================================

def run_inference(input_csv: str, output_csv: str):
    """
    Main inference pipeline:
      1. Read input CSV
      2. Initialize both optimizers (once)
      3. Process each row based on Flow Type
      4. Write output CSV
    """
    # -- Read input ---------------------------------------------------
    input_path = Path(input_csv)
    if not input_path.exists():
        print(f"[ERROR] Input file not found: {input_path}")
        sys.exit(1)

    df = pd.read_csv(input_path)
    required_cols = {"Date", "Product", "Flow Type", "Quantity"}
    if not required_cols.issubset(set(df.columns)):
        missing = required_cols - set(df.columns)
        print(f"[ERROR] Missing columns in input CSV: {missing}")
        sys.exit(1)

    n_in = len(df[df["Flow Type"] == "Ingoing"])
    n_out = len(df[df["Flow Type"] == "Outgoing"])
    print(f"[INFO] Loaded {len(df)} order lines from {input_path.name}")
    print(f"       Ingoing:  {n_in} lines")
    print(f"       Outgoing: {n_out} lines")
    print()

    # -- Initialize optimizers ----------------------------------------
    route_optimizer = None
    storage_optimizer = None

    has_outgoing = (df["Flow Type"] == "Outgoing").any()
    has_ingoing = (df["Flow Type"] == "Ingoing").any()

    if has_outgoing:
        print("[INIT] Building Route Optimizer (for outgoing orders) ...")
        route_optimizer = RouteOptimizer()
        print("[OK]   Route Optimizer ready\n")

    if has_ingoing:
        print("[INIT] Building Storage Optimizer (for ingoing orders) ...")
        storage_optimizer = WarehouseOptimizer()
        print(f"[OK]   Storage Optimizer ready -- "
              f"{len(storage_optimizer.product_features)} products, "
              f"{len(storage_optimizer.slot_meta)} storage cells\n")

        # Cap slot capacity for realistic per-unit assignment
        CAP_PER_CELL = 0.05
        for key in storage_optimizer.slot_meta:
            storage_optimizer.slot_meta[key]["remaining_m3"] = CAP_PER_CELL
            storage_optimizer.slot_meta[key]["total_capacity_m3"] = CAP_PER_CELL
            storage_optimizer.slot_meta[key]["used_m3"] = 0.0
        storage_optimizer._initial_slot_meta = copy.deepcopy(storage_optimizer.slot_meta)
        for floor in storage_optimizer.available_targets:
            for t in storage_optimizer.available_targets[floor]:
                t["available_m3"] = CAP_PER_CELL

    # -- Process each order line --------------------------------------
    output_rows = []

    print("=" * 100)
    print("  PROCESSING ORDERS")
    print("=" * 100)

    for idx, row in df.iterrows():
        date = row["Date"]
        product_id = str(row["Product"])
        flow_type = row["Flow Type"]
        quantity = int(row["Quantity"])

        print(f"\n[{idx+1}/{len(df)}] {date} | Product {product_id} | {flow_type} | qty={quantity}")

        if flow_type == "Outgoing":
            # -- PICKING: find route from storage to expedition ----
            result = route_optimizer.find_route_by_product(product_id, qty=1)

            if "error" in result:
                print(f"  [WARN] {result['error']}")
                output_rows.append({
                    "Date": date,
                    "Product": product_id,
                    "Action": "Picking",
                    "Quantity": quantity,
                    "Location": "N/A",
                    "Route": "N/A",
                    "Reason": result["error"],
                })
            else:
                location = result.get("emplacement_code",
                                      result.get("source_slot_id", "?"))
                route_desc = build_route_description_outgoing(result, route_optimizer)
                reason = build_reason_outgoing(result)

                print(f"  [OK] {location}")
                print(f"       Route: {route_desc}")
                output_rows.append({
                    "Date": date,
                    "Product": product_id,
                    "Action": "Picking",
                    "Quantity": quantity,
                    "Location": location,
                    "Route": route_desc,
                    "Reason": reason,
                })

        elif flow_type == "Ingoing":
            # -- STORAGE: find best slot for incoming product ------
            result = storage_optimizer.find_best_slot(
                product_id, update_capacity=True
            )

            if result is None:
                feat_exists = product_id in storage_optimizer.product_features
                reason = ("Product not found in catalog"
                          if not feat_exists
                          else "No capacity available in any slot")
                print(f"  [WARN] {reason}")
                output_rows.append({
                    "Date": date,
                    "Product": product_id,
                    "Action": "Storage",
                    "Quantity": quantity,
                    "Location": "N/A",
                    "Route": "N/A",
                    "Reason": reason,
                })
            else:
                location = result["emplacement_code"]
                route_desc = build_route_description_ingoing(result, storage_optimizer)
                reason = build_reason_ingoing(result)

                print(f"  [OK] -> {location}")
                print(f"       Route: {route_desc}")
                output_rows.append({
                    "Date": date,
                    "Product": product_id,
                    "Action": "Storage",
                    "Quantity": quantity,
                    "Location": location,
                    "Route": route_desc,
                    "Reason": reason,
                })
        else:
            print(f"  [WARN] Unknown flow type: {flow_type}")
            output_rows.append({
                "Date": date,
                "Product": product_id,
                "Action": "Unknown",
                "Quantity": quantity,
                "Location": "N/A",
                "Route": "N/A",
                "Reason": f"Unknown flow type: {flow_type}",
            })

    # -- Write output CSV ---------------------------------------------
    output_df = pd.DataFrame(output_rows)
    output_path = Path(output_csv)
    output_df.to_csv(output_path, index=False)

    # -- Print summary ------------------------------------------------
    print()
    print("=" * 100)
    print("  INFERENCE RESULTS SUMMARY")
    print("=" * 100)

    for i, r in enumerate(output_rows, 1):
        print(f"\n  [{i}] {r['Date']} | {r['Product']} | {r['Action']} | qty={r['Quantity']}")
        print(f"      Location: {r['Location']}")
        print(f"      Route:    {r['Route']}")
        print(f"      Reason:   {r['Reason']}")

    print()
    print("-" * 100)

    # Stats
    actions = output_df["Action"].value_counts()
    success = output_df[output_df["Location"] != "N/A"]
    failed = output_df[output_df["Location"] == "N/A"]

    print(f"  Total operations:  {len(output_df)}")
    for action, count in actions.items():
        print(f"    {action}: {count}")
    print(f"  Successful:        {len(success)}")
    if len(failed) > 0:
        print(f"  Failed:            {len(failed)}")
    print(f"\n  Output saved to: {output_path.resolve()}")
    print("=" * 100)


# =====================================================================
# CLI
# =====================================================================

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Unified Warehouse Inference -- Routes (Outgoing) & Storage (Ingoing)"
    )
    parser.add_argument(
        "--input", "-i",
        default=str(_THIS_DIR / "test_orders.csv"),
        help="Path to input CSV (Date, Product, Flow Type, Quantity)",
    )
    parser.add_argument(
        "--output", "-o",
        default=str(_THIS_DIR / "inference_output.csv"),
        help="Path to output CSV",
    )
    args = parser.parse_args()

    run_inference(args.input, args.output)
