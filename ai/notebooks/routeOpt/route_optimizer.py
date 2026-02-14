"""
Warehouse Route Optimization — Product-to-Ground-Floor Path Finder
==================================================================

Given one or more **product IDs** (with optional quantities), finds where
each product is stored on floors 1–4, picks the source slot that minimizes
total travel distance to the ground floor, and returns the full path +
exact ground-floor position.

Data flow:
  product_id  →  inventory JSON (which slots hold it & how many)
              →  emplacements CSV  (slot code → floor + grid slot)
              →  floor grid matrices (floor, row, col)
              →  route to best ground-floor target

Pathfinding:
  • BFS pre-computes distance maps from chariot exits (for fast cost lookup)
  • A* (Manhattan heuristic) reconstructs actual paths for each leg
    — explores fewer nodes than BFS for targeted single-destination queries

Usage:
    # From command line — by product ID:
    python route_optimizer.py --product-id 31496
    python route_optimizer.py --product-id 31496 34016
    python route_optimizer.py --product-id 31496 --qty 500

    # By slot ID on upper floors (still supported):
    python route_optimizer.py --slot-id A1 B7

    # By (floor, row, col) (still supported):
    python route_optimizer.py --position 1 0 1

    # As a module:
    from route_optimizer import RouteOptimizer
    optimizer = RouteOptimizer()

    # By product ID — finds best source slot, returns route
    result = optimizer.find_route_by_product("31496")
    result = optimizer.find_route_by_product("31496", qty=500)
    results = optimizer.find_routes_by_products(["31496", "34016"])

    # By slot ID (finds all occurrences on floors 1–4)
    results = optimizer.find_route_by_slot("A1")

    # By explicit position
    result = optimizer.find_route(floor=1, row=0, col=1)

    # Batch mode — list of (floor, row, col)
    results = optimizer.find_routes([(1, 0, 1), (2, 4, 10), (3, 2, 5)])
"""

import numpy as np
import pandas as pd
import json
import re
import heapq
import matplotlib.pyplot as plt
from matplotlib.colors import ListedColormap
import matplotlib.patches as mpatches
import os
import sys
import argparse
from collections import deque
from pathlib import Path


# ═══════════════════════════════════════════════════════════════════════
# DIRECTORY SETUP
# ═══════════════════════════════════════════════════════════════════════
_THIS_DIR = Path(__file__).resolve().parent
_STORAGE_OPT_DIR = _THIS_DIR / ".." / "storageOpt"
_DATA_DIR = _THIS_DIR / ".." / ".." / "data" / "processed"
_INVENTORY_JSON = _DATA_DIR / "emplacement_inventory_with_volumes.json"

# Regex to parse RESERVE code_emplacement: B07-N{floor}-{slot}
_RE_RESERVE_CODE = re.compile(r"^B07-N(\d+)-(.+)$")


class RouteOptimizer:
    """
    Full warehouse route optimization engine.

    On construction, loads all layout CSVs, builds floor matrices,
    walkability grids, BFS distance maps from every chariot elevator,
    and identifies all ground-floor targets (shelves + exhibition zones).

    Then answers:
        "Given a storage cell on floor 1–4, what is the best path
         to the ground floor and where exactly does it end up?"
    """

    # ── Cell-type codes ─────────────────────────────────────────────
    CODE_AISLE      = 0
    CODE_STORAGE    = 1   # floors 1–4: pallet | floor 0: shelf
    CODE_ELEVATOR   = 2
    CODE_CHARIOT    = 3
    CODE_OBSTACLE   = 4
    CODE_VRAC       = 5   # ground only — bulk storage (walkable)
    CODE_EXHIBITION = 6   # ground only — exhibition (walkable target)
    CODE_BUREAU     = 7   # ground only — office (blocked)

    CODE_LABELS = {
        0: "Aisle", 1: "Storage/Shelf", 2: "Elevator",
        3: "Chariot Elevator", 4: "Obstacle",
        5: "VRAC", 6: "Exhibition", 7: "Bureau",
    }

    # ── Walkability sets ────────────────────────────────────────────
    WALKABLE_GROUND = {0, 3, 5, 6}        # aisle, chariot, vrac, exhibition
    WALKABLE_UPPER  = {0, 3}              # aisle, chariot (full transit)
    DEADEND_UPPER   = {1}                 # storage — reachable but no transit

    # ── Shelf parsing ───────────────────────────────────────────────
    SHELF_SPOTS_PER_SHELF = 3
    RE_FULL_SHELF   = re.compile(r"\((\d[A-Z]-\d{2}-\d{2})\)")
    RE_SINGLE_LETTER = re.compile(r"\(([A-Z])\)")

    def __init__(
        self,
        route_opt_dir: str | Path | None = None,
        storage_opt_dir: str | Path | None = None,
        inventory_json: str | Path | None = None,
        chariot_transit_cost_per_floor: int = 10,
        straight_cost: int = 1,
    ):
        """
        Parameters
        ----------
        route_opt_dir : folder containing Book3.csv (ground floor layout).
                        Defaults to the directory of this script.
        storage_opt_dir : folder containing Book1.csv, Book2.csv, emplacements.csv.
                          Defaults to ../storageOpt relative to this script.
        inventory_json : path to emplacement_inventory_with_volumes.json.
                         Defaults to ../../data/processed/...
        chariot_transit_cost_per_floor : fixed cost per floor via chariot elevator.
        straight_cost : cost to move one grid cell (manhattan).
        """
        self.route_opt_dir = Path(route_opt_dir) if route_opt_dir else _THIS_DIR
        self.storage_opt_dir = Path(storage_opt_dir) if storage_opt_dir else _STORAGE_OPT_DIR
        self.inventory_json_path = Path(inventory_json) if inventory_json else _INVENTORY_JSON

        self.CHARIOT_TRANSIT_COST = chariot_transit_cost_per_floor
        self.STRAIGHT_COST = straight_cost

        # ── Build everything ──
        self._build_all()

    # ═══════════════════════════════════════════════════════════════
    #  PUBLIC API
    # ═══════════════════════════════════════════════════════════════

    def find_route(self, floor: int, row: int, col: int,
                  target_type: str = "shelf") -> dict:
        """Find the optimal route from a single source cell to the ground floor.

        Parameters
        ----------
        floor : source floor (1–4)
        row, col : grid position on the source floor
        target_type : 'shelf', 'exhibition', or 'all'. Default 'shelf'
                      (matching the notebook — products go to shelves).

        Returns
        -------
        dict with keys:
            source          : (floor, row, col)
            source_slot_id  : str or None
            target_slot_id  : str  (e.g. "0A-01-01" or "EXH-003")
            target_type     : "shelf" or "exhibition"
            target_shelf_cells : [(row, col), ...] — shelf's own grid cells
            access_point    : (row, col) — walkable cell adjacent to shelf
            total_cost      : int
            leg1_path       : [(floor, row, col), ...] — source → chariot
            leg2_transit    : (src_floor, 0)
            leg2_cost       : int
            leg3_path       : [(0, row, col), ...] — chariot → access point
            src_chariot     : (row, col) on source floor
            gf_chariot      : (row, col) on ground floor
        """
        if floor < 1 or floor > 4:
            raise ValueError(f"Source floor must be 1–4, got {floor}")

        t = self.floor_matrices[floor]["type"]
        if row < 0 or row >= t.shape[0] or col < 0 or col >= t.shape[1]:
            raise ValueError(
                f"Position ({row},{col}) out of bounds for floor {floor} "
                f"(shape {t.shape[0]}×{t.shape[1]})"
            )

        # Find the best target across ground-floor targets
        best = self._find_best_target(floor, row, col, target_type=target_type)
        if best is None:
            return {
                "source": (floor, row, col),
                "source_slot_id": self._get_slot_id(floor, row, col),
                "error": "No reachable target found on ground floor",
            }

        # Reconstruct full path
        result = self._reconstruct_full_path(
            floor, row, col,
            best["access_points"],
        )
        if result is None:
            return {
                "source": (floor, row, col),
                "source_slot_id": self._get_slot_id(floor, row, col),
                "error": "Path reconstruction failed",
            }

        return {
            "source": (floor, row, col),
            "source_slot_id": self._get_slot_id(floor, row, col),
            "target_slot_id": best["label"],
            "target_type": best["type"],
            "target_shelf_cells": best.get("shelf_cells", []),
            "access_point": result["best_access_point"],
            "total_cost": result["total_cost"],
            "leg1_path": result["leg1_path"],
            "leg2_transit": result["leg2_floors"],
            "leg2_cost": floor * self.CHARIOT_TRANSIT_COST,
            "leg3_path": result["leg3_path"],
            "src_chariot": result["src_chariot"],
            "gf_chariot": result["gf_chariot"],
        }

    def find_routes(self, positions: list[tuple[int, int, int]],
                    target_type: str = "shelf") -> list[dict]:
        """Find routes for multiple source positions.

        Parameters
        ----------
        positions : list of (floor, row, col) tuples
        target_type : 'shelf', 'exhibition', or 'all'. Default 'shelf'.

        Returns
        -------
        list of result dicts (same format as find_route)
        """
        return [self.find_route(fl, r, c, target_type=target_type)
                for fl, r, c in positions]

    def find_route_by_product(self, product_id: str, qty: int = 1,
                              target_type: str = "shelf") -> dict:
        """Find the best route for a product, picking the source slot that
        minimizes distance to the ground floor.

        Parameters
        ----------
        product_id : product ID (string, e.g. "31496")
        qty : required quantity (default 1). Only slots with >= qty are considered.
        target_type : 'shelf', 'exhibition', or 'all'. Default 'shelf'
                      (products are stored on shelves on the ground floor).

        Returns
        -------
        dict with all fields from find_route(), plus:
            product_id       : str
            requested_qty    : int
            available_qty    : int   — quantity of the product in the chosen slot
            emplacement_id   : str   — id_emplacement in the DB
            emplacement_code : str   — code_emplacement (e.g. B07-N2-A1)
            candidate_slots  : int   — how many slots had this product
        """
        product_id = str(product_id)

        # Find all emplacements that hold this product with enough qty
        candidates = self._find_product_locations(product_id, qty)
        if not candidates:
            return {
                "product_id": product_id,
                "requested_qty": qty,
                "error": (
                    f"Product '{product_id}' not found in inventory"
                    if not self._find_product_locations(product_id, 0)
                    else f"Product '{product_id}' found but no slot has >= {qty} units"
                ),
            }

        # Compute route for each candidate, pick the one with min cost
        best_result = None
        best_cost = np.inf

        for cand in candidates:
            fl, r, c = cand["floor"], cand["row"], cand["col"]
            try:
                route = self.find_route(fl, r, c, target_type=target_type)
            except ValueError:
                continue

            if "error" in route:
                continue

            if route["total_cost"] < best_cost:
                best_cost = route["total_cost"]
                best_result = route
                best_result["product_id"] = product_id
                best_result["requested_qty"] = qty
                best_result["available_qty"] = cand["qty"]
                best_result["emplacement_id"] = cand["emplacement_id"]
                best_result["emplacement_code"] = cand["emplacement_code"]
                best_result["candidate_slots"] = len(candidates)

        if best_result is None:
            return {
                "product_id": product_id,
                "requested_qty": qty,
                "candidate_slots": len(candidates),
                "error": "Product found but no reachable route to ground floor",
            }

        return best_result

    def find_routes_by_products(
        self,
        product_ids: list[str],
        quantities: list[int] | None = None,
        target_type: str = "shelf",
    ) -> list[dict]:
        """Find best routes for multiple products.

        Parameters
        ----------
        product_ids : list of product IDs
        quantities : optional list of required quantities (default 1 each)
        target_type : 'shelf', 'exhibition', or 'all'. Default 'shelf'.

        Returns
        -------
        list of result dicts (same format as find_route_by_product)
        """
        if quantities is None:
            quantities = [1] * len(product_ids)
        if len(quantities) != len(product_ids):
            raise ValueError("product_ids and quantities must have the same length")

        return [
            self.find_route_by_product(pid, q, target_type=target_type)
            for pid, q in zip(product_ids, quantities)
        ]

    def find_route_by_slot(self, slot_id: str) -> list[dict]:
        """Find routes for all cells matching a slot ID on floors 1–4.

        Parameters
        ----------
        slot_id : e.g. "A1", "B7", "C12"

        Returns
        -------
        list of result dicts (one per matching cell; may be multiple
        because the same slot_id can appear on floors 1&2 and 3&4).
        """
        matches = []
        for fl in range(1, 5):
            s = self.floor_matrices[fl]["slots"]
            rows_f, cols_f = s.shape
            for i in range(rows_f):
                for j in range(cols_f):
                    if s[i, j] == slot_id:
                        matches.append((fl, i, j))

        if not matches:
            raise ValueError(
                f"Slot ID '{slot_id}' not found on any upper floor (1–4)"
            )

        return [self.find_route(fl, r, c) for fl, r, c in matches]

    def print_result(self, result: dict) -> None:
        """Pretty-print a single route result."""
        print("=" * 70)
        print("  ROUTE OPTIMIZATION RESULT")
        print("=" * 70)

        # Product info (if routed by product)
        if "product_id" in result:
            print(f"  Product ID:       {result['product_id']}")
            print(f"  Requested Qty:    {result['requested_qty']}")
            if "available_qty" in result:
                print(f"  Available Qty:    {result['available_qty']}")
            if "emplacement_code" in result:
                print(f"  Emplacement:      {result['emplacement_code']}")
            if "candidate_slots" in result:
                print(f"  Candidate Slots:  {result['candidate_slots']}")

        if "error" in result:
            print(f"  ERROR:            {result['error']}")
            print("=" * 70)
            return

        src = result["source"]
        print(f"  Source:           floor {src[0]}, row {src[1]}, col {src[2]}")
        print(f"  Source Slot ID:   {result.get('source_slot_id', 'N/A')}")

        print(f"  Target Slot ID:   {result['target_slot_id']}")
        print(f"  Target Type:      {result['target_type']}")
        print(f"  Target Cells:     {result['target_shelf_cells']}")
        print(f"  Access Point:     row={result['access_point'][0]}, "
              f"col={result['access_point'][1]}")
        print("-" * 70)
        print(f"  Total Cost:       {result['total_cost']}")
        print(f"  Leg 1 (floor {src[0]}): {len(result['leg1_path'])} steps "
              f"  source → chariot {result['src_chariot']}")
        print(f"  Leg 2 (transit):   floor {result['leg2_transit'][0]} → "
              f"floor {result['leg2_transit'][1]}  "
              f"  cost = {result['leg2_cost']}")
        print(f"  Leg 3 (ground):    {len(result['leg3_path'])} steps "
              f"  chariot {result['gf_chariot']} → "
              f"access pt {result['access_point']}")
        print("-" * 70)

        # Print leg 1 path
        print(f"  Leg 1 path on Floor {src[0]} ({len(result['leg1_path'])} cells):")
        cells_str = " → ".join(
            f"({p[1]},{p[2]})" for p in result["leg1_path"]
        )
        # Wrap long lines
        if len(cells_str) > 60:
            cells = [f"({p[1]},{p[2]})" for p in result["leg1_path"]]
            for i in range(0, len(cells), 10):
                chunk = " → ".join(cells[i:i + 10])
                prefix = "    " if i == 0 else "      "
                print(f"{prefix}{chunk}")
        else:
            print(f"    {cells_str}")

        # Print leg 3 path
        print(f"  Leg 3 path on Ground Floor ({len(result['leg3_path'])} cells):")
        cells_str = " → ".join(
            f"({p[1]},{p[2]})" for p in result["leg3_path"]
        )
        if len(cells_str) > 60:
            cells = [f"({p[1]},{p[2]})" for p in result["leg3_path"]]
            for i in range(0, len(cells), 10):
                chunk = " → ".join(cells[i:i + 10])
                prefix = "    " if i == 0 else "      "
                print(f"{prefix}{chunk}")
        else:
            print(f"    {cells_str}")

        print("=" * 70)

    def visualize(self, result, save_path=None):
        """
        Visualize route legs on floor maps (matplotlib).

        Shows two subplots:
          - Leg 1: source → chariot on the source floor
          - Leg 3: chariot → access point on the ground floor

        Parameters
        ----------
        result : dict
            Output from find_route(), find_route_by_product(), etc.
        save_path : str, optional
            If given, saves the figure to this path instead of showing it.
        """
        if result is None:
            print("Nothing to visualize (result is None).")
            return

        src_floor = result["source"][0]
        leg1 = result["leg1_path"]
        leg3 = result["leg3_path"]

        if not leg1 and not leg3:
            print("No path cells to visualize.")
            return

        # ── colour map for ground floor ──
        gf_cmap_colors = [
            "#FFFFFF",   # 0 aisle
            "#8B4513",   # 1 shelf
            "#FFD700",   # 2 elevator
            "#00BFFF",   # 3 chariot
            "#333333",   # 4 obstacle
            "#90EE90",   # 5 VRAC
            "#FF69B4",   # 6 exhibition
            "#FF4500",   # 7 bureau
        ]
        gf_cmap = ListedColormap(gf_cmap_colors)
        gf_patches = [
            mpatches.Patch(color=c, label=l)
            for c, l in zip(
                gf_cmap_colors,
                ["Aisle", "Shelf", "Elevator", "Chariot",
                 "Obstacle", "VRAC", "Exhibition", "Bureau"],
            )
        ]

        fig, axes = plt.subplots(1, 2, figsize=(16, 6))

        # ── Leg 1 — source floor ──
        ax1 = axes[0]
        ax1.imshow(
            self.floor_matrices[src_floor]["type"],
            cmap="tab20", origin="upper",
        )
        if leg1:
            leg1_rs = [p[1] for p in leg1]
            leg1_cs = [p[2] for p in leg1]
            ax1.plot(leg1_cs, leg1_rs, "r-o",
                     markersize=2, linewidth=1.5, label="Leg 1 path")
            ax1.plot(leg1_cs[0], leg1_rs[0], "gs",
                     markersize=8, label="Source")
            ax1.plot(leg1_cs[-1], leg1_rs[-1], "b^",
                     markersize=8, label="Chariot (src)")
        ax1.set_title(f"Leg 1 — Floor {src_floor}")
        ax1.legend(fontsize=8, loc="upper right")

        # ── Leg 3 — ground floor ──
        ax3 = axes[1]
        ax3.imshow(
            self.floor_matrices[0]["type"],
            cmap=gf_cmap, origin="upper",
            vmin=0, vmax=len(gf_cmap_colors) - 1,
        )
        if leg3:
            leg3_rs = [p[1] for p in leg3]
            leg3_cs = [p[2] for p in leg3]
            ax3.plot(leg3_cs, leg3_rs, "r-o",
                     markersize=2, linewidth=1.5, label="Leg 3 path")
            ax3.plot(leg3_cs[0], leg3_rs[0], "b^",
                     markersize=8, label="Chariot (GF)")
            target_label = result.get("target_slot_id", "target")
            ax3.plot(leg3_cs[-1], leg3_rs[-1], "m*",
                     markersize=12, label=f"Access pt → {target_label}")
        ax3.set_title("Leg 3 — Ground Floor")
        ax3.legend(fontsize=8, loc="upper right",
                   handles=([
                       mpatches.Patch(color="red", label="Leg 3 path"),
                       mpatches.Patch(color="blue", label="Chariot (GF)"),
                       mpatches.Patch(color="magenta", label="Access pt"),
                   ] + gf_patches))

        # ── title info ──
        title_parts = [
            f"Floor {src_floor} → Ground",
            f"cost = {result['total_cost']}",
        ]
        if "product_id" in result:
            title_parts.insert(0, f"Product {result['product_id']}")
        plt.suptitle("  |  ".join(title_parts), fontsize=13)
        plt.tight_layout()

        if save_path:
            fig.savefig(save_path, dpi=150, bbox_inches="tight")
            print(f"Figure saved to {save_path}")
        else:
            plt.show()

    def visualize_multi(self, results, save_path=None):
        """
        Visualize routes for multiple products side by side.

        Each product gets a row of two subplots (Leg 1 + Leg 3).

        Parameters
        ----------
        results : list[dict]
            List of result dicts from find_routes_by_products(), etc.
        save_path : str, optional
            If given, saves the figure to this path instead of showing it.
        """
        valid = [r for r in results if r is not None and r.get("leg1_path")]
        if not valid:
            print("Nothing to visualize.")
            return

        n = len(valid)
        fig, axes = plt.subplots(n, 2, figsize=(16, 5 * n), squeeze=False)

        gf_cmap_colors = [
            "#FFFFFF", "#8B4513", "#FFD700", "#00BFFF",
            "#333333", "#90EE90", "#FF69B4", "#FF4500",
        ]
        gf_cmap = ListedColormap(gf_cmap_colors)

        for i, result in enumerate(valid):
            src_floor = result["source"][0]
            leg1 = result["leg1_path"]
            leg3 = result["leg3_path"]

            # Leg 1
            ax1 = axes[i][0]
            ax1.imshow(self.floor_matrices[src_floor]["type"],
                       cmap="tab20", origin="upper")
            if leg1:
                rs = [p[1] for p in leg1]
                cs = [p[2] for p in leg1]
                ax1.plot(cs, rs, "r-o", markersize=2, linewidth=1.5,
                         label="Leg 1 path")
                ax1.plot(cs[0], rs[0], "gs", markersize=8, label="Source")
                ax1.plot(cs[-1], rs[-1], "b^", markersize=8,
                         label="Chariot (src)")
            lbl = result.get("product_id", "")
            ax1.set_title(f"Leg 1 — Floor {src_floor}"
                          + (f"  [Product {lbl}]" if lbl else ""))
            ax1.legend(fontsize=7, loc="upper right")

            # Leg 3
            ax3 = axes[i][1]
            ax3.imshow(self.floor_matrices[0]["type"],
                       cmap=gf_cmap, origin="upper",
                       vmin=0, vmax=len(gf_cmap_colors) - 1)
            if leg3:
                rs = [p[1] for p in leg3]
                cs = [p[2] for p in leg3]
                ax3.plot(cs, rs, "r-o", markersize=2, linewidth=1.5,
                         label="Leg 3 path")
                ax3.plot(cs[0], rs[0], "b^", markersize=8,
                         label="Chariot (GF)")
                tgt = result.get("target_slot_id", "target")
                ax3.plot(cs[-1], rs[-1], "m*", markersize=12,
                         label=f"Access pt → {tgt}")
            ax3.set_title(f"Leg 3 — Ground Floor  (cost={result['total_cost']})")
            ax3.legend(fontsize=7, loc="upper right")

        plt.suptitle("Warehouse Route Visualization", fontsize=14)
        plt.tight_layout()

        if save_path:
            fig.savefig(save_path, dpi=150, bbox_inches="tight")
            print(f"Figure saved to {save_path}")
        else:
            plt.show()

    # ═══════════════════════════════════════════════════════════════
    #  INTERNAL — Build pipeline
    # ═══════════════════════════════════════════════════════════════

    def _build_all(self):
        """Run the full build pipeline (mirrors notebook steps 0–6)."""
        self._load_floor_matrices()      # Step 1
        self._build_walkability()         # Step 3
        self._identify_targets()          # Step 4
        self._run_bfs_all_floors()        # Step 5
        self._build_slot_index()          # helper for slot lookups
        self._load_inventory()            # inventory + emplacement mapping

    # ── Step 1: Load & parse CSVs ───────────────────────────────
    def _load_floor_matrices(self):
        csv_12 = self.storage_opt_dir / "Book1.csv"
        csv_34 = self.storage_opt_dir / "Book2.csv"
        csv_ground = self.route_opt_dir / "Book3.csv"

        raw_12 = np.genfromtxt(csv_12, delimiter=",", dtype=str)
        raw_34 = np.genfromtxt(csv_34, delimiter=",", dtype=str)
        raw_ground = np.genfromtxt(csv_ground, delimiter=",", dtype=str)

        type_12, slot_12 = self._parse_upper_floor(raw_12)
        type_34, slot_34 = self._parse_upper_floor(raw_34)
        type_gf, slot_gf = self._parse_ground_floor(raw_ground)

        self.floor_matrices = {
            0: {"type": type_gf,          "slots": slot_gf},
            1: {"type": type_12.copy(),   "slots": slot_12.copy()},
            2: {"type": type_12.copy(),   "slots": slot_12.copy()},
            3: {"type": type_34.copy(),   "slots": slot_34.copy()},
            4: {"type": type_34.copy(),   "slots": slot_34.copy()},
        }

    def _parse_upper_floor(self, raw):
        rows, cols = raw.shape
        type_mat = np.zeros((rows, cols), dtype=int)
        slot_mat = np.empty((rows, cols), dtype=object)

        for i in range(rows):
            for j in range(cols):
                cell = raw[i, j].strip()
                if not cell or not cell[-1].isdigit():
                    type_mat[i, j] = self.CODE_AISLE
                    slot_mat[i, j] = None
                    continue

                cell_type = int(cell[-1])
                type_mat[i, j] = cell_type

                if cell_type == self.CODE_STORAGE:
                    match = re.search(r"\((.*?)\)", cell)
                    slot_mat[i, j] = match.group(1) if match else None
                else:
                    slot_mat[i, j] = None

        return type_mat, slot_mat

    def _parse_ground_floor(self, raw):
        rows, cols = raw.shape

        # Pass 1: find first row each single-letter section appears
        section_first_row = {}
        for i in range(rows):
            for j in range(cols):
                cell = raw[i, j].strip()
                if not cell or not cell[-1].isdigit():
                    continue
                if int(cell[-1]) != self.CODE_STORAGE:
                    continue
                m = self.RE_SINGLE_LETTER.search(cell)
                if m:
                    sec = m.group(1)
                    if sec not in section_first_row:
                        section_first_row[sec] = i

        # Pass 2: build matrices
        type_mat = np.zeros((rows, cols), dtype=int)
        slot_mat = np.empty((rows, cols), dtype=object)

        for i in range(rows):
            for j in range(cols):
                cell = raw[i, j].strip()
                if not cell or not cell[-1].isdigit():
                    type_mat[i, j] = self.CODE_AISLE
                    slot_mat[i, j] = None
                    continue

                cell_type = int(cell[-1])
                type_mat[i, j] = cell_type

                if cell_type != self.CODE_STORAGE:
                    slot_mat[i, j] = None
                    continue

                # Full shelf label: (0W-01-01)
                m_full = self.RE_FULL_SHELF.search(cell)
                if m_full:
                    slot_mat[i, j] = m_full.group(1)
                    continue

                # Single-letter label: (A)
                m_letter = self.RE_SINGLE_LETTER.search(cell)
                if m_letter:
                    section = m_letter.group(1)
                    start = section_first_row[section]
                    shelf_num = (i - start) // self.SHELF_SPOTS_PER_SHELF + 1
                    spot = (i - start) % self.SHELF_SPOTS_PER_SHELF + 1
                    slot_mat[i, j] = f"0{section}-{shelf_num:02d}-{spot:02d}"
                    continue

                slot_mat[i, j] = None

        return type_mat, slot_mat

    # ── Step 3: Walkability ─────────────────────────────────────
    def _build_walkability(self):
        self.walkability = {}
        for fl in range(5):
            t = self.floor_matrices[fl]["type"]
            rows_f, cols_f = t.shape
            w = np.zeros((rows_f, cols_f), dtype=int)

            if fl == 0:
                for i in range(rows_f):
                    for j in range(cols_f):
                        if int(t[i, j]) in self.WALKABLE_GROUND:
                            w[i, j] = 1
            else:
                for i in range(rows_f):
                    for j in range(cols_f):
                        code = int(t[i, j])
                        if code in self.WALKABLE_UPPER:
                            w[i, j] = 1
                        elif code in self.DEADEND_UPPER:
                            w[i, j] = 2  # dead-end: reachable, no transit
            self.walkability[fl] = w

    # ── Step 4: Targets ─────────────────────────────────────────
    def _identify_targets(self):
        t0 = self.floor_matrices[0]["type"]
        s0 = self.floor_matrices[0]["slots"]
        w0 = self.walkability[0]
        rows_0, cols_0 = t0.shape

        # Shelf targets
        self.shelf_targets = {}  # slot_id → {"cells": [...], "access_points": [...]}
        for i in range(rows_0):
            for j in range(cols_0):
                if int(t0[i, j]) == self.CODE_STORAGE and s0[i, j] is not None:
                    sid = s0[i, j]
                    if sid not in self.shelf_targets:
                        self.shelf_targets[sid] = {
                            "cells": [], "access_points": set()
                        }
                    self.shelf_targets[sid]["cells"].append((i, j))
                    aps = self._get_access_points(w0, i, j)
                    self.shelf_targets[sid]["access_points"].update(aps)

        for sid in self.shelf_targets:
            self.shelf_targets[sid]["access_points"] = sorted(
                self.shelf_targets[sid]["access_points"]
            )

        # Exhibition targets
        self.exhibition_targets = []
        for i in range(rows_0):
            for j in range(cols_0):
                if int(t0[i, j]) == self.CODE_EXHIBITION:
                    self.exhibition_targets.append((i, j))

        # Unified target list
        self.all_targets = []
        for sid in sorted(self.shelf_targets.keys()):
            aps = self.shelf_targets[sid]["access_points"]
            if aps:
                self.all_targets.append({
                    "label": sid,
                    "type": "shelf",
                    "access_points": aps,
                    "shelf_cells": self.shelf_targets[sid]["cells"],
                })
        for idx, (er, ec) in enumerate(self.exhibition_targets):
            self.all_targets.append({
                "label": f"EXH-{idx:03d}",
                "type": "exhibition",
                "access_points": [(er, ec)],
                "shelf_cells": [(er, ec)],
            })

    def _get_access_points(self, walk_mat, row, col):
        H, W = walk_mat.shape
        neighbors = [(row - 1, col), (row + 1, col),
                     (row, col - 1), (row, col + 1)]
        return [(r, c) for r, c in neighbors
                if 0 <= r < H and 0 <= c < W and walk_mat[r, c] == 1]

    # ── Step 5: BFS ─────────────────────────────────────────────
    def _run_bfs_all_floors(self):
        self.chariot_positions_per_floor = {}
        self.dist_from_chariot = {}

        for fl in range(5):
            t = self.floor_matrices[fl]["type"]
            positions = list(zip(*np.where(t == self.CODE_CHARIOT)))
            self.chariot_positions_per_floor[fl] = positions

            w = self.walkability[fl]
            floor_dists = []
            for cr, cc in positions:
                d = self._bfs_from(w, cr, cc)
                floor_dists.append((cr, cc, d))
            self.dist_from_chariot[fl] = floor_dists

    def _bfs_from(self, walk_mat, start_r, start_c):
        """BFS distance from (start_r, start_c).
        Returns 2D array: dist[r][c] = steps or -1 if unreachable.
        """
        H, W = walk_mat.shape
        dist = np.full((H, W), -1, dtype=int)
        dist[start_r, start_c] = 0
        queue = deque([(start_r, start_c)])

        while queue:
            r, c = queue.popleft()
            for dr, dc in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                nr, nc = r + dr, c + dc
                if (0 <= nr < H and 0 <= nc < W
                        and walk_mat[nr, nc] >= 1
                        and dist[nr, nc] == -1):
                    dist[nr, nc] = dist[r, c] + self.STRAIGHT_COST
                    if walk_mat[nr, nc] == 1:
                        queue.append((nr, nc))

        return dist

    def _bfs_with_parents(self, walk_mat, start_r, start_c):
        """BFS with parent tracking for path reconstruction (fallback)."""
        H, W = walk_mat.shape
        dist = np.full((H, W), -1, dtype=int)
        parent = np.full((H, W, 2), -1, dtype=int)
        dist[start_r, start_c] = 0
        queue = deque([(start_r, start_c)])

        while queue:
            r, c = queue.popleft()
            for dr, dc in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                nr, nc = r + dr, c + dc
                if (0 <= nr < H and 0 <= nc < W
                        and walk_mat[nr, nc] >= 1
                        and dist[nr, nc] == -1):
                    dist[nr, nc] = dist[r, c] + self.STRAIGHT_COST
                    parent[nr, nc] = [r, c]
                    if walk_mat[nr, nc] == 1:
                        queue.append((nr, nc))

        return dist, parent

    @staticmethod
    def _astar(start: tuple[int, int], goal: tuple[int, int],
               walk_mat: np.ndarray) -> list[tuple[int, int]] | None:
        """
        A* pathfinding from start to goal on the walkability grid.

        Uses Manhattan distance as heuristic (admissible & consistent for
        4-connected grids with uniform cost), guaranteeing optimal paths
        while expanding fewer nodes than BFS.

        Walkability codes:
          0 = blocked
          1 = fully walkable (transit allowed)
          2 = dead-end (reachable as destination, no transit through)

        Parameters
        ----------
        start : (row, col) starting position.
        goal  : (row, col) target position.
        walk_mat : integer matrix (0=blocked, 1=walkable, 2=dead-end).

        Returns
        -------
        List of (row, col) from start to goal, or None if unreachable.
        """
        rows, cols = walk_mat.shape
        sr, sc = start
        gr, gc = goal

        if not (0 <= sr < rows and 0 <= sc < cols):
            return None
        if not (0 <= gr < rows and 0 <= gc < cols):
            return None
        if walk_mat[sr, sc] == 0 and (sr, sc) != goal:
            return None
        if (sr, sc) == (gr, gc):
            return [(sr, sc)]

        # Manhattan distance heuristic — admissible for 4-connected grid
        def h(r: int, c: int) -> int:
            return abs(r - gr) + abs(c - gc)

        # Priority queue: (f_score, tie_breaker, row, col)
        counter = 0
        open_set = [(h(sr, sc), counter, sr, sc)]
        came_from: dict[tuple[int, int], tuple[int, int]] = {}
        g_score: dict[tuple[int, int], int] = {(sr, sc): 0}
        closed: set[tuple[int, int]] = set()

        directions = [(-1, 0), (1, 0), (0, -1), (0, 1)]

        while open_set:
            f, _, r, c = heapq.heappop(open_set)

            if (r, c) == (gr, gc):
                # Reconstruct path
                path = [(r, c)]
                while (r, c) in came_from:
                    r, c = came_from[(r, c)]
                    path.append((r, c))
                path.reverse()
                return path

            if (r, c) in closed:
                continue
            closed.add((r, c))

            # Dead-end cells (walkability=2): reachable but don't expand
            # through them — unless it's the start cell
            if walk_mat[r, c] == 2 and (r, c) != (sr, sc):
                continue

            current_g = g_score[(r, c)]
            for dr, dc in directions:
                nr, nc = r + dr, c + dc
                if 0 <= nr < rows and 0 <= nc < cols and walk_mat[nr, nc] >= 1:
                    if (nr, nc) in closed:
                        continue
                    tentative_g = current_g + 1
                    if tentative_g < g_score.get((nr, nc), float("inf")):
                        came_from[(nr, nc)] = (r, c)
                        g_score[(nr, nc)] = tentative_g
                        counter += 1
                        heapq.heappush(
                            open_set,
                            (tentative_g + h(nr, nc), counter, nr, nc),
                        )

        return None  # No path found

    # ── Slot index for quick lookup ─────────────────────────────
    def _build_slot_index(self):
        """Build reverse index: slot_id → [(floor, row, col), ...]"""
        self.slot_index = {}
        for fl in range(1, 5):
            s = self.floor_matrices[fl]["slots"]
            rows_f, cols_f = s.shape
            for i in range(rows_f):
                for j in range(cols_f):
                    if s[i, j] is not None:
                        sid = s[i, j]
                        self.slot_index.setdefault(sid, []).append((fl, i, j))

    # ── Inventory + emplacement mapping ─────────────────────────
    def _load_inventory(self):
        """Load inventory JSON + emplacements CSV.

        Builds:
          self.inventory : raw JSON data (id_emplacement → product info)
          self.emplacements_df : DataFrame of emplacements
          self.product_locations : product_id → list of location dicts
        """
        # Load inventory JSON
        with open(self.inventory_json_path, "r") as f:
            self.inventory = json.load(f)

        # Load emplacements
        self.emplacements_df = pd.read_csv(
            self.storage_opt_dir / "emplacements.csv"
        )

        # Build id→code mapping
        self._eid_to_code = dict(zip(
            self.emplacements_df["id_emplacement"].astype(str),
            self.emplacements_df["code_emplacement"],
        ))

        # Build product → locations index
        # For each product, find which emplacements hold it, resolve to (floor, row, col)
        self.product_locations = {}  # product_id → [{ emplacement_id, code, floor, row, col, qty }, ...]

        for eid_str, info in self.inventory.items():
            code = self._eid_to_code.get(eid_str)
            if not code:
                continue

            # Parse code_emplacement to extract floor + grid slot
            # RESERVE format: B07-N{floor}-{slot}  e.g. B07-N2-A1 → floor 2, slot A1
            m = _RE_RESERVE_CODE.match(code)
            if not m:
                continue  # skip ground-floor PICKING, EXPEDITION, etc.

            floor_num = int(m.group(1))
            grid_slot = m.group(2)  # e.g. "A1", "B7", "E11"

            if floor_num < 1 or floor_num > 4:
                continue

            # Find grid positions for this slot on this specific floor
            grid_positions = [
                (fl, r, c) for fl, r, c in self.slot_index.get(grid_slot, [])
                if fl == floor_num
            ]
            if not grid_positions:
                continue

            # Register for each product in this emplacement
            for pid_str, qty in info["products"].items():
                loc_entry = {
                    "emplacement_id": eid_str,
                    "emplacement_code": code,
                    "floor": floor_num,
                    "grid_slot": grid_slot,
                    "grid_positions": grid_positions,
                    "qty": qty,
                }
                self.product_locations.setdefault(pid_str, []).append(loc_entry)

    def _find_product_locations(self, product_id: str, min_qty: int = 1):
        """Return list of candidate locations for a product.

        Each candidate: { emplacement_id, emplacement_code, floor, row, col, qty }
        Only the best grid position (nearest to chariot) per emplacement is kept.
        """
        product_id = str(product_id)
        locs = self.product_locations.get(product_id, [])

        candidates = []
        for loc in locs:
            if loc["qty"] < min_qty:
                continue

            # Pick the grid position with lowest BFS distance to chariot
            best_pos = None
            best_dist = np.inf
            for fl, r, c in loc["grid_positions"]:
                for _, _, dist_mat in self.dist_from_chariot[fl]:
                    d = dist_mat[r, c]
                    if 0 <= d < best_dist:
                        best_dist = d
                        best_pos = (fl, r, c)

            if best_pos is None:
                continue

            candidates.append({
                "emplacement_id": loc["emplacement_id"],
                "emplacement_code": loc["emplacement_code"],
                "floor": best_pos[0],
                "row": best_pos[1],
                "col": best_pos[2],
                "grid_slot": loc["grid_slot"],
                "qty": loc["qty"],
            })

        return candidates

    # ═══════════════════════════════════════════════════════════════
    #  INTERNAL — Path computation
    # ═══════════════════════════════════════════════════════════════

    def _get_slot_id(self, floor, row, col):
        """Get the slot ID at a given position, or None."""
        s = self.floor_matrices[floor]["slots"]
        if 0 <= row < s.shape[0] and 0 <= col < s.shape[1]:
            return s[row, col]
        return None

    def _full_path_cost(self, src_floor, src_row, src_col, target_access_points):
        """Compute min 3-leg cost from source to target access points.

        Returns (total_cost, src_chariot, gf_chariot, best_access_point)
        or (inf, None, None, None) if unreachable.
        """
        best_cost = np.inf
        best_src_ch = None
        best_gf_ch = None
        best_ap = None

        for cr_s, cc_s, dist_s in self.dist_from_chariot[src_floor]:
            leg1 = dist_s[src_row, src_col]
            if leg1 < 0:
                continue

            leg2 = src_floor * self.CHARIOT_TRANSIT_COST

            for cr_g, cc_g, dist_g in self.dist_from_chariot[0]:
                for ap_r, ap_c in target_access_points:
                    leg3 = dist_g[ap_r, ap_c]
                    if leg3 < 0:
                        continue

                    total = leg1 + leg2 + leg3
                    if total < best_cost:
                        best_cost = total
                        best_src_ch = (cr_s, cc_s)
                        best_gf_ch = (cr_g, cc_g)
                        best_ap = (ap_r, ap_c)

        if best_cost == np.inf:
            return (np.inf, None, None, None)
        return (int(best_cost), best_src_ch, best_gf_ch, best_ap)

    def _find_best_target(self, src_floor, src_row, src_col,
                          target_type: str = "shelf"):
        """Find the target with minimum cost from the given source.

        Parameters
        ----------
        target_type : 'shelf', 'exhibition', or 'all'. Default 'shelf'.

        Returns target dict with added 'cost' and 'access_point' keys, or None.
        """
        # Filter targets by type
        if target_type == "all":
            candidates = self.all_targets
        else:
            candidates = [t for t in self.all_targets
                          if t["type"] == target_type]

        best_cost = np.inf
        best_target = None
        best_ap = None

        for tgt in candidates:
            cost, ch_s, ch_g, ap = self._full_path_cost(
                src_floor, src_row, src_col, tgt["access_points"]
            )
            if cost < best_cost:
                best_cost = cost
                best_target = tgt
                best_ap = ap

        if best_target is None or best_cost == np.inf:
            return None

        return {
            **best_target,
            "cost": int(best_cost),
            "best_access_point": best_ap,
        }

    def _reconstruct_path(self, parent, start_r, start_c, end_r, end_c):
        """Trace back from end to start using parent matrix."""
        path = []
        r, c = end_r, end_c
        while not (r == start_r and c == start_c):
            path.append((r, c))
            pr, pc = parent[r, c]
            if pr == -1 and pc == -1:
                return None  # unreachable
            r, c = int(pr), int(pc)
        path.append((start_r, start_c))
        path.reverse()
        return path

    def _reconstruct_full_path(self, src_floor, src_row, src_col,
                                target_access_points):
        """Reconstruct full 3-leg path from source to ground floor target
        using A* search with Manhattan distance heuristic.

        Falls back to BFS with parent tracking if A* fails.

        Returns dict with leg paths, chariot positions, etc., or None.
        """
        cost, best_src_ch, best_gf_ch, best_ap = self._full_path_cost(
            src_floor, src_row, src_col, target_access_points
        )
        if cost == np.inf:
            return None

        # Leg 1: A* from source → chariot on source floor
        w_src = self.walkability[src_floor]
        leg1_cells = self._astar(
            (src_row, src_col), best_src_ch, w_src
        )
        if leg1_cells is None:
            # Fallback: BFS from chariot → source, then reverse
            _, parent_src = self._bfs_with_parents(
                w_src, best_src_ch[0], best_src_ch[1]
            )
            leg1_cells = self._reconstruct_path(
                parent_src, best_src_ch[0], best_src_ch[1], src_row, src_col
            )
            if leg1_cells is None:
                return None
            leg1_cells = list(reversed(leg1_cells))
        leg1_path = [(src_floor, r, c) for r, c in leg1_cells]

        # Leg 3: A* from chariot → access point on ground floor
        w_gf = self.walkability[0]
        leg3_cells = self._astar(
            best_gf_ch, best_ap, w_gf
        )
        if leg3_cells is None:
            # Fallback: BFS from chariot → access point
            _, parent_gf = self._bfs_with_parents(
                w_gf, best_gf_ch[0], best_gf_ch[1]
            )
            leg3_cells = self._reconstruct_path(
                parent_gf, best_gf_ch[0], best_gf_ch[1], best_ap[0], best_ap[1]
            )
            if leg3_cells is None:
                return None
        leg3_path = [(0, r, c) for r, c in leg3_cells]

        return {
            "total_cost": cost,
            "leg1_path": leg1_path,
            "leg2_floors": (src_floor, 0),
            "leg3_path": leg3_path,
            "best_access_point": best_ap,
            "src_chariot": best_src_ch,
            "gf_chariot": best_gf_ch,
        }

    # ═══════════════════════════════════════════════════════════════
    #  Utility: list available slot IDs on upper floors
    # ═══════════════════════════════════════════════════════════════

    def list_upper_slots(self) -> list[str]:
        """Return sorted list of unique slot IDs on floors 1–4."""
        return sorted(self.slot_index.keys())

    def list_ground_targets(self) -> list[str]:
        """Return sorted list of all target labels on ground floor."""
        return [t["label"] for t in self.all_targets]


# ═══════════════════════════════════════════════════════════════════════
#  CLI
# ═══════════════════════════════════════════════════════════════════════

def main():
    parser = argparse.ArgumentParser(
        description="Warehouse Route Optimizer — find optimal path from "
                    "upper-floor storage to ground-floor shelf/exhibition."
    )
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        "--product-id", nargs="+",
        help="One or more product IDs (e.g. 31496 34016)"
    )
    group.add_argument(
        "--slot-id", nargs="+",
        help="One or more slot IDs on floors 1–4 (e.g. A1 B7 C12)"
    )
    group.add_argument(
        "--position", nargs=3, type=int, metavar=("FLOOR", "ROW", "COL"),
        help="Source position as floor row col (e.g. 1 0 1)"
    )
    group.add_argument(
        "--list-slots", action="store_true",
        help="List all available slot IDs on upper floors"
    )
    group.add_argument(
        "--list-products", action="store_true",
        help="List all product IDs available in inventory"
    )
    parser.add_argument(
        "--qty", type=int, default=1,
        help="Required quantity per product (default: 1)"
    )

    args = parser.parse_args()

    print("Loading warehouse data & building BFS maps...")
    optimizer = RouteOptimizer()
    print("Ready.\n")

    if args.list_slots:
        slots = optimizer.list_upper_slots()
        print(f"Available slot IDs on floors 1–4 ({len(slots)} unique):")
        for s in slots:
            positions = optimizer.slot_index[s]
            floors = sorted(set(fl for fl, _, _ in positions))
            print(f"  {s:<8s}  floors {floors}  ({len(positions)} cells)")
        return

    if args.list_products:
        products = sorted(optimizer.product_locations.keys())
        print(f"Products in inventory ({len(products)} unique):")
        for pid in products:
            locs = optimizer.product_locations[pid]
            total_qty = sum(l["qty"] for l in locs)
            floors = sorted(set(l["floor"] for l in locs))
            print(f"  {pid:<10s}  qty={total_qty:<8}  "
                  f"floors {floors}  ({len(locs)} slot(s))")
        return

    results = []
    if args.product_id:
        for pid in args.product_id:
            res = optimizer.find_route_by_product(pid, qty=args.qty)
            results.append(res)
    elif args.slot_id:
        for sid in args.slot_id:
            try:
                res = optimizer.find_route_by_slot(sid)
                results.extend(res)
            except ValueError as e:
                print(f"ERROR: {e}\n")
    elif args.position:
        fl, r, c = args.position
        try:
            res = optimizer.find_route(fl, r, c)
            results.append(res)
        except ValueError as e:
            print(f"ERROR: {e}\n")

    for result in results:
        optimizer.print_result(result)
        print()


if __name__ == "__main__":
    main()
