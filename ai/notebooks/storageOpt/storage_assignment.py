"""
Warehouse Storage Optimization — Assignment Engine (MILP + BFS)
================================================================

Takes a product (by ID or features) as input, builds the entire warehouse
state on demand (floor matrices, slot metadata, walkability grids, BFS
distances), finds the optimal storage slot, and returns the path + an
illustration figure.

Pathfinding:
  • BFS pre-computes distance maps from chariot exits (for fast cost lookup)
  • A* (Manhattan heuristic) reconstructs actual paths to assigned slots
    — explores fewer nodes than BFS for targeted single-destination queries

Supports:
  • Single-product assignment  (greedy enumeration — optimal for 1 product)
  • Batch assignment via MILP  (Mixed Integer Linear Programming using HiGHS)

Mathematical Formulation (batch mode)
-------------------------------------
  Decision Variables:  x[p,s] ∈ {0,1}  — 1 iff product p assigned to slot s
  Objective:  min Σ_{p,s} cost(p,s) · x[p,s]
  where:
    cost(p,s) = α·D_receipt(s)_norm
              + β·demand_freq(p)_norm · D_expedition(s)_norm
              + δ·reception_freq(p)_norm · D_receipt(s)_norm
    
    Default weights (optimized for picking operations):
      α = 0.8   (moderate receipt distance priority)
      β = 3.5   (HIGH demand/expedition priority — A-items near ground)
      δ = 0.7   (lower reception frequency impact)
  Subject to:
    (1)  Σ_s x[p,s] = 1              ∀p   (each product → exactly one slot)
    (2)  Σ_p vol(p)·x[p,s] ≤ cap(s)  ∀s   (slot capacity respected)

Usage:
    # Single product:
    python storage_assignment.py --product-id "SOME-PRODUCT-ID"

    # Batch MILP optimization:
    python storage_assignment.py --product-ids ID1 ID2 ID3

    # As a module:
    from storage_assignment import WarehouseOptimizer
    optimizer = WarehouseOptimizer()
    result  = optimizer.assign_product("SOME-PRODUCT-ID")
    results = optimizer.optimize_batch_assignment(["ID1", "ID2", "ID3"])
    optimizer.visualize(result)
"""

import numpy as np
import pandas as pd
import json
import re
import copy
import os
import argparse
import heapq
from collections import deque
from pathlib import Path

try:
    from scipy.optimize import linprog
    _HAS_SCIPY_MILP = True
except ImportError:
    _HAS_SCIPY_MILP = False

import matplotlib
# Use interactive backend if available, fall back to Agg for headless/save-only
try:
    matplotlib.use("TkAgg")
except Exception:
    matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.colors import ListedColormap


# ═══════════════════════════════════════════════════════════════════════
# DATA DIRECTORY — all CSVs and JSONs live here
# ═══════════════════════════════════════════════════════════════════════
_THIS_DIR = Path(__file__).resolve().parent


class WarehouseOptimizer:
    """
    Full warehouse storage optimization engine.

    On construction it loads all data files, builds matrices, slot metadata,
    walkability grids, BFS distance maps, product features, and cost-function
    helpers — everything needed to answer:

        "Given product X, where should I store it and how do I get there?"
    """

    # ── Layout encoding ─────────────────────────────────────────────
    # 0 = aisle, 1 = storage slot, 2 = elevator, 3 = chariot, 4 = obstacle
    FLOOR_COLORS = ["white", "lightblue", "lightgreen", "red", "black"]
    CMAP = ListedColormap(FLOOR_COLORS)

    def __init__(
        self,
        data_dir: str | Path | None = None,
        max_capacity_m3: float = 10_000.0,
        ascend_cost_per_floor: int = 8,
        alpha: float = 0.8,
        beta: float = 3.5,
        delta: float = 0.7,
    ):
        """
        Parameters
        ----------
        data_dir : path to the folder containing Book1.csv, Book2.csv,
                   produits.csv, transactions.csv, lignes_transaction.csv,
                   emplacements.csv, emplacement_available_slots.json.
                   Defaults to the directory of this script.
        max_capacity_m3 : Max m³ capacity per emplacement.
        ascend_cost_per_floor : Meters-equivalent cost to go up one floor (default: 8m).
        alpha : Cost weight for receipt distance (default: 0.8).
        beta : Cost weight for demand×expedition distance (default: 3.5, highest priority).
        delta : Cost weight for reception×receipt distance (default: 0.7).
        """
        self.data_dir = Path(data_dir) if data_dir else _THIS_DIR
        self.MAX_CAPACITY_M3 = max_capacity_m3
        self.ASCEND_COST_PER_FLOOR = ascend_cost_per_floor
        self.ALPHA = alpha
        self.BETA = beta
        self.DELTA = delta

        # Populated by _build_all()
        self.floor_matrices: dict = {}
        self.slot_meta: dict = {}
        self.walkable: dict = {}
        self.chariot_positions: dict = {}
        self.available_targets: dict = {}
        self.distance_from_chariot: dict = {}
        self.distance_to_expedition: dict = {}
        self.product_features: dict = {}
        self.DIST_MIN: int = 0
        self.DIST_MAX: int = 1
        self.assignment_log: list = []

        # Initial snapshots for reset
        self._initial_slot_meta = {}
        self._initial_walkable = {}
        self._initial_available = {}

        # Build everything
        self._build_all()

    # ═══════════════════════════════════════════════════════════════════
    # PRIVATE — Pipeline Steps
    # ═══════════════════════════════════════════════════════════════════

    def _build_all(self):
        """Run the full pipeline: load → parse → metadata → walkability →
        BFS → cost helpers → snapshot initial state."""
        self._step1_load_floor_matrices()
        self._step1b_load_product_features()
        self._step2_build_slot_metadata()
        self._step3_build_walkability()
        self._step4_find_sources_and_targets()
        self._step5_bfs_distances()
        self._snapshot_initial_state()

    # ── Step 1: Load & parse CSV floor layouts ──────────────────────

    @staticmethod
    def _parse_floor_csv(raw: np.ndarray, rows: int, cols: int):
        """Parse a raw CSV matrix into type_matrix (int) and slot_matrix (str|None)."""
        type_mat = np.zeros((rows, cols), dtype=int)
        slot_mat = np.empty((rows, cols), dtype=object)

        for i in range(rows):
            for j in range(cols):
                cell = raw[i, j].strip()
                if not cell or not cell[-1].isdigit():
                    type_mat[i, j] = 0
                    slot_mat[i, j] = None
                    continue

                cell_type = int(cell[-1])
                type_mat[i, j] = cell_type

                if cell_type == 1:
                    match = re.search(r"\((.*?)\)", cell)
                    slot_mat[i, j] = match.group(1) if match else None
                else:
                    slot_mat[i, j] = None

        return type_mat, slot_mat

    def _step1_load_floor_matrices(self):
        csv1 = self.data_dir / "Book1.csv"
        csv2 = self.data_dir / "Book2.csv"
        raw1 = np.genfromtxt(csv1, delimiter=",", dtype=str)
        raw2 = np.genfromtxt(csv2, delimiter=",", dtype=str)

        t1, s1 = self._parse_floor_csv(raw1, *raw1.shape)
        t2, s2 = self._parse_floor_csv(raw2, *raw2.shape)

        self.floor_matrices = {
            1: {"type": t1.copy(), "slots": s1.copy()},
            2: {"type": t1.copy(), "slots": s1.copy()},
            3: {"type": t2.copy(), "slots": s2.copy()},
            4: {"type": t2.copy(), "slots": s2.copy()},
        }

    # ── Step 1b: Product features, demand & reception freq ─────────

    def _step1b_load_product_features(self):
        produits_df = pd.read_csv(self.data_dir / "produits.csv", skiprows=[1, 2])
        transactions_df = pd.read_csv(self.data_dir / "transactions.csv", skiprows=[1, 2])
        lignes_df = pd.read_csv(self.data_dir / "lignes_transaction.csv", skiprows=[1, 2], low_memory=False)

        lignes_df["id_transaction"] = lignes_df["id_transaction"].astype(str)
        transactions_df["id_transaction"] = transactions_df["id_transaction"].astype(str)
        lignes_df["id_produit"] = lignes_df["id_produit"].astype(str)
        produits_df["id_produit"] = produits_df["id_produit"].astype(str)

        lines_with_type = lignes_df.merge(
            transactions_df[["id_transaction", "type_transaction", "cree_le"]],
            on="id_transaction",
            how="left",
        )

        OUTBOUND_TYPE = "DELIVERY"
        INBOUND_TYPE = "RECEIPT"

        demand_freq = (
            lines_with_type[lines_with_type["type_transaction"] == OUTBOUND_TYPE]
            .groupby("id_produit")["quantite"]
            .sum()
            .rename("demand_freq")
        )

        reception_freq = (
            lines_with_type[lines_with_type["type_transaction"] == INBOUND_TYPE]
            .groupby("id_produit")["id_transaction"]
            .nunique()
            .rename("reception_freq")
        )

        # Build features dict
        product_features: dict = {}
        for _, row in produits_df.iterrows():
            pid = str(row["id_produit"])
            product_features[pid] = {
                "nom": row.get("nom_produit", ""),
                "categorie": row.get("categorie", ""),
                "weight_kg": float(row.get("Poids(kg)", 0) or 0),
                "volume_m3": float(row.get("volume pcs (m3)", 0) or 0),
                "colisage_pal": float(row.get("colisage palette", 0) or 0),
                "is_gerbable": bool(row.get("Is_Gerbable", False)),
                "demand_freq": float(demand_freq.get(pid, 0)),
                "reception_freq": float(reception_freq.get(pid, 0)),
            }

        # Normalize
        all_weights = [p["weight_kg"] for p in product_features.values()]
        all_demands = [p["demand_freq"] for p in product_features.values()]
        all_receipts = [p["reception_freq"] for p in product_features.values()]

        for pid, feat in product_features.items():
            feat["norm_weight"] = self._minmax(feat["weight_kg"], all_weights)
            feat["norm_demand_freq"] = self._minmax(feat["demand_freq"], all_demands)
            feat["norm_reception_freq"] = self._minmax(feat["reception_freq"], all_receipts)

        # A/B/C classification
        sorted_by_demand = sorted(
            product_features.items(), key=lambda x: x[1]["demand_freq"], reverse=True
        )
        n = len(sorted_by_demand)
        for i, (pid, feat) in enumerate(sorted_by_demand):
            if i < n * 0.2:
                feat["abc_class"] = "A"
            elif i < n * 0.5:
                feat["abc_class"] = "B"
            else:
                feat["abc_class"] = "C"

        self.product_features = product_features

    @staticmethod
    def _minmax(val, vals):
        mn, mx = min(vals), max(vals)
        return (val - mn) / (mx - mn) if mx > mn else 0.0

    # ── Step 2: Slot metadata (with capacity tracking) ─────────────

    def _calculate_storage_priority(self, floor, slot_id, row, col):
        match = re.match(r"([A-Z]+)(\d+)", slot_id)
        if not match:
            return 999
        letter = match.group(1)
        num = int(match.group(2))

        if floor in [1, 2]:
            if letter in ["A", "B"]:
                return 20 - num
            elif letter == "E":
                return 20 - num
            elif letter in ["C", "D"]:
                return abs(num - 5)
            else:
                return 50
        elif floor in [3, 4]:
            matrix_height = self.floor_matrices[floor]["slots"].shape[0]
            dist_from_edge = min(row, matrix_height - row - 1)
            return dist_from_edge * 10 + (20 - num)
        return 100

    def _step2_build_slot_metadata(self):
        avail_path = self.data_dir / "emplacement_available_slots.json"
        emplacements_df = pd.read_csv(self.data_dir / "emplacements.csv")
        reserve = emplacements_df[emplacements_df["type_emplacement"] == "RESERVE"].copy()

        try:
            with open(avail_path, "r") as f:
                available_slots = json.load(f)
        except FileNotFoundError:
            available_slots = {}

        code_to_metadata = {}
        for _, row in reserve.iterrows():
            code = row["code_emplacement"]
            emp_id = row["id_emplacement"]
            avail = available_slots.get(str(emp_id), 0)
            code_to_metadata[code] = {"id_emplacement": emp_id, "available_m3": avail}

        # First pass: count cells per emplacement
        emplacement_cell_count: dict[str, int] = {}
        for floor in [1, 2, 3, 4]:
            slot_mat = self.floor_matrices[floor]["slots"]
            for r in range(slot_mat.shape[0]):
                for c in range(slot_mat.shape[1]):
                    sid = slot_mat[r, c]
                    if sid is not None:
                        code = f"B07-N{floor}-{sid}"
                        emplacement_cell_count[code] = emplacement_cell_count.get(code, 0) + 1

        # Second pass: build slot_meta
        slot_meta: dict = {}
        unmatched_id = 2000
        for floor in [1, 2, 3, 4]:
            slot_mat = self.floor_matrices[floor]["slots"]
            for r in range(slot_mat.shape[0]):
                for c in range(slot_mat.shape[1]):
                    sid = slot_mat[r, c]
                    if sid is None:
                        continue
                    code = f"B07-N{floor}-{sid}"
                    cell_count = emplacement_cell_count[code]
                    priority = self._calculate_storage_priority(floor, sid, r, c)

                    if code in code_to_metadata:
                        meta = code_to_metadata[code]
                        total = self.MAX_CAPACITY_M3 / cell_count
                        remaining = meta["available_m3"] / cell_count
                        used = total - remaining
                        slot_meta[(floor, r, c)] = {
                            "slot_id": sid,
                            "emplacement_code": code,
                            "id_emplacement": meta["id_emplacement"],
                            "total_capacity_m3": total,
                            "used_m3": used,
                            "remaining_m3": remaining,
                            "storage_priority": priority,
                        }
                    else:
                        total = self.MAX_CAPACITY_M3 / cell_count
                        slot_meta[(floor, r, c)] = {
                            "slot_id": sid,
                            "emplacement_code": code,
                            "id_emplacement": unmatched_id,
                            "total_capacity_m3": total,
                            "used_m3": 0.0,
                            "remaining_m3": total,
                            "storage_priority": priority,
                        }
                        unmatched_id += 1

        self.slot_meta = slot_meta

    # ── Step 3: Walkability grid ───────────────────────────────────

    def _step3_build_walkability(self):
        walkable: dict = {}
        for floor in [1, 2, 3, 4]:
            t = self.floor_matrices[floor]["type"]
            w = np.zeros(t.shape, dtype=bool)
            for r in range(t.shape[0]):
                for c in range(t.shape[1]):
                    ct = t[r, c]
                    if ct in [0, 2, 3]:
                        w[r, c] = True
                    elif ct == 1:
                        info = self.slot_meta.get((floor, r, c))
                        if info and info["remaining_m3"] == info["total_capacity_m3"]:
                            w[r, c] = True
            walkable[floor] = w
        self.walkable = walkable

    # ── Step 4: Sources (chariots) & targets (available slots) ─────

    def _step4_find_sources_and_targets(self):
        chariot_positions: dict = {}
        available_targets: dict = {}
        for floor in [1, 2, 3, 4]:
            t = self.floor_matrices[floor]["type"]
            chariot_positions[floor] = [
                (r, c)
                for r in range(t.shape[0])
                for c in range(t.shape[1])
                if t[r, c] == 3
            ]
            targets = []
            for r in range(t.shape[0]):
                for c in range(t.shape[1]):
                    if t[r, c] == 1:
                        info = self.slot_meta.get((floor, r, c))
                        if info and info["remaining_m3"] > 0:
                            targets.append(
                                {
                                    "position": (r, c),
                                    "emplacement_id": info["id_emplacement"],
                                    "emplacement_code": info["emplacement_code"],
                                    "available_m3": info["remaining_m3"],
                                }
                            )
            available_targets[floor] = targets
        self.chariot_positions = chariot_positions
        self.available_targets = available_targets

    # ── Step 5: BFS distance maps ──────────────────────────────────

    @staticmethod
    def _bfs_distance(start_pos, walkable_grid: np.ndarray) -> np.ndarray:
        rows, cols = walkable_grid.shape
        sr, sc = start_pos
        distances = np.full((rows, cols), -1, dtype=int)
        if not (0 <= sr < rows and 0 <= sc < cols) or not walkable_grid[sr, sc]:
            return distances
        distances[sr, sc] = 0
        queue = deque([(sr, sc, 0)])
        directions = [(-1, 0), (1, 0), (0, -1), (0, 1)]
        while queue:
            r, c, dist = queue.popleft()
            for dr, dc in directions:
                nr, nc = r + dr, c + dc
                if 0 <= nr < rows and 0 <= nc < cols:
                    if walkable_grid[nr, nc] and distances[nr, nc] == -1:
                        distances[nr, nc] = dist + 1
                        queue.append((nr, nc, dist + 1))
        return distances

    def _step5_bfs_distances(self):
        distance_from_chariot: dict = {}
        for floor in [1, 2, 3, 4]:
            wg = self.walkable[floor]
            positions = self.chariot_positions[floor]
            if not positions:
                distance_from_chariot[floor] = np.full(wg.shape, -1, dtype=int)
                continue
            combined = self._bfs_distance(positions[0], wg)
            for pos in positions[1:]:
                d = self._bfs_distance(pos, wg)
                for r in range(wg.shape[0]):
                    for c in range(wg.shape[1]):
                        d1, d2 = combined[r, c], d[r, c]
                        if d1 == -1:
                            combined[r, c] = d2
                        elif d2 != -1:
                            combined[r, c] = min(d1, d2)
            distance_from_chariot[floor] = combined
        self.distance_from_chariot = distance_from_chariot

        # Expedition shares same elevator for now
        self.distance_to_expedition = {
            f: d.copy() for f, d in distance_from_chariot.items()
        }

        # Normalize range
        all_dists = []
        for floor in [1, 2, 3, 4]:
            d = self.distance_from_chariot[floor]
            all_dists.extend(d[d >= 0].tolist())
        if all_dists:
            self.DIST_MIN = min(all_dists)
            self.DIST_MAX = max(all_dists)
        else:
            self.DIST_MIN, self.DIST_MAX = 0, 1

    # ── Snapshot / Reset ───────────────────────────────────────────

    def _snapshot_initial_state(self):
        self._initial_slot_meta = copy.deepcopy(self.slot_meta)
        self._initial_walkable = {f: w.copy() for f, w in self.walkable.items()}
        self._initial_available = copy.deepcopy(self.available_targets)

    def reset(self):
        """Reset warehouse state to the initial snapshot (undo all assignments)."""
        self.slot_meta = copy.deepcopy(self._initial_slot_meta)
        self.walkable = {f: w.copy() for f, w in self._initial_walkable.items()}
        self.available_targets = copy.deepcopy(self._initial_available)
        self.assignment_log = []

    # ═══════════════════════════════════════════════════════════════════
    # PUBLIC — Cost Function & Assignment
    # ═══════════════════════════════════════════════════════════════════

    def _norm_dist(self, val: int) -> float:
        """Normalize a raw BFS walk distance (without elevator cost)."""
        return (val - self.DIST_MIN) / (self.DIST_MAX - self.DIST_MIN) if self.DIST_MAX > self.DIST_MIN else 0.0

    def _norm_dist_total(self, val: float) -> float:
        """Normalize a total distance (elevator + walk) to [0, 1]."""
        # Max total = 4 floors × ascend_cost + max walk distance
        total_max = 4 * self.ASCEND_COST_PER_FLOOR + self.DIST_MAX
        # Min total = 1 floor × ascend_cost + min walk distance
        total_min = 1 * self.ASCEND_COST_PER_FLOOR + self.DIST_MIN
        return (val - total_min) / (total_max - total_min) if total_max > total_min else 0.0

    def compute_cost(self, product_id: str, floor: int, row: int, col: int) -> float:
        """
        Compute placement cost for product_id at slot (floor, row, col).

        The TOTAL distance from ground floor (0) to the slot is:
           D_total = elevator_cost(floor) + BFS_walk_on_floor

        Cost = α·D_total_receipt(norm)
             + β·F_demand(norm)·D_total_expedition(norm)
             + δ·F_reception(norm)·D_total_receipt(norm)
        
        With optimized defaults (α=0.8, β=3.5, δ=0.7):
        - High-demand (A-class) items prioritized for low expedition distance
        - Lower floors and slots near elevators strongly preferred for frequent picks
        """
        feat = self.product_features.get(str(product_id))
        if not feat:
            return float("inf")
        d_walk_receipt = self.distance_from_chariot[floor][row, col]
        d_walk_expedition = self.distance_to_expedition[floor][row, col]
        if d_walk_receipt < 0 or d_walk_expedition < 0:
            return float("inf")

        # Add elevator cost: going from ground (floor 0) UP to this floor
        elevator_cost = floor * self.ASCEND_COST_PER_FLOOR
        d_receipt = d_walk_receipt + elevator_cost
        d_expedition = d_walk_expedition + elevator_cost

        nr = self._norm_dist_total(d_receipt)
        ne = self._norm_dist_total(d_expedition)
        return (
            self.ALPHA * nr
            + self.BETA * feat["norm_demand_freq"] * ne
            + self.DELTA * feat["norm_reception_freq"] * nr
        )

    def find_best_slot(self, product_id: str, update_capacity: bool = False) -> dict | None:
        """
        Find the optimal storage slot for a product using multi-criteria cost.

        Parameters
        ----------
        product_id : ID of the product (must exist in product_features).
        update_capacity : If True, deducts volume and updates walkability/log.

        Returns
        -------
        dict with slot info + cost + path, or None if no slot fits.
        """
        feat = self.product_features.get(str(product_id))
        if not feat:
            return None

        product_volume = feat["volume_m3"]
        best_cost = float("inf")
        best_key = None

        for (floor, r, c), info in self.slot_meta.items():
            if info["remaining_m3"] < product_volume:
                continue
            if self.distance_from_chariot[floor][r, c] < 0:
                continue
            cost = self.compute_cost(product_id, floor, r, c)
            if cost < best_cost:
                best_cost = cost
                best_key = (floor, r, c)

        if best_key is None:
            return None

        floor, r, c = best_key
        info = self.slot_meta[best_key]
        path = self.reconstruct_path(floor, r, c)
        walk_distance = (len(path) - 1) if path else -1
        elevator_cost = floor * self.ASCEND_COST_PER_FLOOR
        total_distance = elevator_cost + walk_distance if walk_distance >= 0 else -1

        if update_capacity:
            self.slot_meta[best_key]["used_m3"] += product_volume
            self.slot_meta[best_key]["remaining_m3"] -= product_volume
            new_remaining = self.slot_meta[best_key]["remaining_m3"]

            if new_remaining <= 0.001:
                self.walkable[floor][r, c] = False
                self.available_targets[floor] = [
                    t for t in self.available_targets[floor] if t["position"] != (r, c)
                ]
            else:
                for t in self.available_targets[floor]:
                    if t["position"] == (r, c):
                        t["available_m3"] = new_remaining
                        break

            self.assignment_log.append(
                {
                    "seq": len(self.assignment_log) + 1,
                    "product_id": str(product_id),
                    "abc_class": feat["abc_class"],
                    "volume_m3": product_volume,
                    "emplacement_code": info["emplacement_code"],
                    "floor": floor,
                    "position": (r, c),
                    "cost": best_cost,
                    "remaining_m3": self.slot_meta[best_key]["remaining_m3"],
                    "walk_distance": walk_distance,
                    "elevator_cost": elevator_cost,
                    "total_distance": total_distance,
                }
            )

        return {
            "product_id": str(product_id),
            "emplacement_code": info["emplacement_code"],
            "id_emplacement": info["id_emplacement"],
            "floor": floor,
            "position": (r, c),
            "cost": best_cost,
            "remaining_capacity_m3": self.slot_meta[best_key]["remaining_m3"],
            "product_volume_m3": product_volume,
            "abc_class": feat["abc_class"],
            "walk_distance": walk_distance,
            "elevator_cost": elevator_cost,
            "total_distance": total_distance,
            "path": path,
        }

    # ═══════════════════════════════════════════════════════════════════
    # PUBLIC — Batch Optimization (MILP)
    # ═══════════════════════════════════════════════════════════════════

    def optimize_batch_assignment(
        self,
        product_ids: list[str],
        update_capacity: bool = False,
        max_candidates_per_product: int = 50,
    ) -> list[dict | None]:
        """
        Solve the storage assignment for a batch of products using
        Mixed Integer Linear Programming (MILP).

        Mathematical Formulation
        ------------------------
        Decision Variables:
            x[p,s] ∈ {0, 1}  — 1 iff product p is assigned to slot s

        Objective (minimize):
            Σ_{p,s} cost(p,s) · x[p,s]

        where:
            cost(p,s) = α · D_receipt_norm(s)
                      + β · demand_freq_norm(p) · D_expedition_norm(s)
                      + δ · reception_freq_norm(p) · D_receipt_norm(s)
            
            Optimized defaults: α=0.8, β=3.5 (highest), δ=0.7
            → Prioritizes low expedition distance for high-demand items

        Subject to:
            (1) Assignment:  Σ_s x[p,s] = 1              ∀p  (each product → one slot)
            (2) Capacity:    Σ_p vol(p)·x[p,s] ≤ cap(s)  ∀s  (slot capacity respected)

        Solver: HiGHS (via scipy.optimize.linprog with integrality constraints)

        Parameters
        ----------
        product_ids : list of product IDs to assign simultaneously.
        update_capacity : if True, commit the assignments (deduct volume).
        max_candidates_per_product : pre-filter to top-N candidates per
            product to keep the problem tractable.

        Returns
        -------
        List of assignment result dicts (same format as find_best_slot),
        one per input product. None entries mean no feasible slot.
        """
        if not _HAS_SCIPY_MILP:
            raise ImportError(
                "scipy is required for MILP optimization. "
                "Install it with:  pip install scipy"
            )

        # ── Validate products ──
        valid: list[str] = []
        for pid in product_ids:
            pid = str(pid)
            if pid in self.product_features:
                valid.append(pid)
            else:
                print(f"  ⚠ Product {pid} not found — skipping")

        if not valid:
            print("  ❌ No valid products to assign.")
            return []

        P = len(valid)

        # ── Pre-filter: top-N candidate slots per product (by cost) ──
        candidate_slots: list[list[tuple]] = []
        for pid in valid:
            feat = self.product_features[pid]
            vol = feat["volume_m3"]
            candidates = []
            for (floor, r, c), info in self.slot_meta.items():
                if info["remaining_m3"] < vol:
                    continue
                if self.distance_from_chariot[floor][r, c] < 0:
                    continue
                cost = self.compute_cost(pid, floor, r, c)
                if cost < float("inf"):
                    candidates.append(((floor, r, c), cost))
            candidates.sort(key=lambda x: x[1])
            candidate_slots.append(candidates[:max_candidates_per_product])

        # ── Build unified slot index ──
        all_keys: set = set()
        for cands in candidate_slots:
            for sk, _ in cands:
                all_keys.add(sk)
        slot_list = sorted(all_keys)
        slot_idx = {sk: i for i, sk in enumerate(slot_list)}
        S = len(slot_list)

        if S == 0:
            print("  ❌ No feasible slots for any product.")
            return [None] * P

        n_vars = P * S

        # ── Cost vector c ──
        c_vec = np.full(n_vars, 1e9)
        feasible = np.zeros((P, S), dtype=bool)
        for p_i, cands in enumerate(candidate_slots):
            for sk, cost in cands:
                s_i = slot_idx[sk]
                c_vec[p_i * S + s_i] = cost
                feasible[p_i, s_i] = True

        # ── Equality constraints: Σ_s x[p,s] = 1  ∀p ──
        A_eq = np.zeros((P, n_vars))
        for p_i in range(P):
            A_eq[p_i, p_i * S : (p_i + 1) * S] = 1.0
        b_eq = np.ones(P)

        # ── Inequality constraints: Σ_p vol(p)·x[p,s] ≤ cap(s)  ∀s ──
        A_ub = np.zeros((S, n_vars))
        b_ub = np.zeros(S)
        for s_i, sk in enumerate(slot_list):
            b_ub[s_i] = self.slot_meta[sk]["remaining_m3"]
            for p_i in range(P):
                if feasible[p_i, s_i]:
                    vol = self.product_features[valid[p_i]]["volume_m3"]
                    A_ub[s_i, p_i * S + s_i] = vol

        # ── Variable bounds & integrality ──
        bounds = [(0, 1)] * n_vars
        for p_i in range(P):
            for s_i in range(S):
                if not feasible[p_i, s_i]:
                    bounds[p_i * S + s_i] = (0, 0)  # infeasible pair → fix to 0

        integrality = np.ones(n_vars, dtype=int)  # 1 = integer (binary with 0-1 bounds)

        print(f"  🔧 MILP formulation:")
        print(f"     {P} products × {S} candidate slots = {n_vars} decision variables")
        print(f"     {P} assignment constraints + {S} capacity constraints")
        print(f"     Solving with HiGHS solver ...")

        # ── Solve ──
        res = linprog(
            c=c_vec,
            A_ub=A_ub,
            b_ub=b_ub,
            A_eq=A_eq,
            b_eq=b_eq,
            bounds=bounds,
            integrality=integrality,
            method="highs",
        )

        if not res.success:
            print(f"  ❌ Optimization failed: {res.message}")
            return [None] * P

        print(f"  ✓ Optimal solution found — total cost: {res.fun:.4f}")

        # ── Extract assignments from solution vector ──
        x = res.x
        assignments: list[dict | None] = []

        for p_i, pid in enumerate(valid):
            feat = self.product_features[pid]
            # Find which slot was selected (x ≈ 1)
            best_s = None
            best_val = -1.0
            for s_i in range(S):
                val = x[p_i * S + s_i]
                if val > best_val:
                    best_val = val
                    best_s = s_i

            if best_s is None or best_val < 0.5:
                print(f"  ⚠ Product {pid} could not be assigned.")
                assignments.append(None)
                continue

            sk = slot_list[best_s]
            floor, r, c = sk
            info = self.slot_meta[sk]
            path = self.reconstruct_path(floor, r, c)
            walk_dist = (len(path) - 1) if path else -1
            elev_cost = floor * self.ASCEND_COST_PER_FLOOR
            total_dist = elev_cost + walk_dist if walk_dist >= 0 else -1

            assignment = {
                "product_id": pid,
                "emplacement_code": info["emplacement_code"],
                "id_emplacement": info["id_emplacement"],
                "floor": floor,
                "position": (r, c),
                "cost": c_vec[p_i * S + best_s],
                "remaining_capacity_m3": info["remaining_m3"] - feat["volume_m3"],
                "product_volume_m3": feat["volume_m3"],
                "abc_class": feat["abc_class"],
                "walk_distance": walk_dist,
                "elevator_cost": elev_cost,
                "total_distance": total_dist,
                "path": path,
            }

            if update_capacity:
                self.slot_meta[sk]["used_m3"] += feat["volume_m3"]
                self.slot_meta[sk]["remaining_m3"] -= feat["volume_m3"]
                new_remaining = self.slot_meta[sk]["remaining_m3"]

                if new_remaining <= 0.001:
                    self.walkable[floor][r, c] = False
                    self.available_targets[floor] = [
                        t for t in self.available_targets[floor]
                        if t["position"] != (r, c)
                    ]
                else:
                    for t in self.available_targets[floor]:
                        if t["position"] == (r, c):
                            t["available_m3"] = new_remaining
                            break

                self.assignment_log.append({
                    "seq": len(self.assignment_log) + 1,
                    "product_id": pid,
                    "abc_class": feat["abc_class"],
                    "volume_m3": feat["volume_m3"],
                    "emplacement_code": info["emplacement_code"],
                    "floor": floor,
                    "position": (r, c),
                    "cost": assignment["cost"],
                    "remaining_m3": self.slot_meta[sk]["remaining_m3"],
                    "walk_distance": walk_dist,
                    "elevator_cost": elev_cost,
                    "total_distance": total_dist,
                })

            assignments.append(assignment)

        return assignments

    # ═══════════════════════════════════════════════════════════════════
    # PUBLIC — Path Reconstruction (A* Search)
    # ═══════════════════════════════════════════════════════════════════

    @staticmethod
    def _astar(start: tuple[int, int], goal: tuple[int, int], walkable_grid: np.ndarray) -> list[tuple[int, int]] | None:
        """
        A* pathfinding from start to goal on the walkable grid.

        Uses Manhattan distance as heuristic (admissible & consistent for
        4-connected grids with uniform cost), guaranteeing optimal paths
        while expanding fewer nodes than BFS.

        Parameters
        ----------
        start : (row, col) starting position (e.g. chariot exit).
        goal  : (row, col) target position (e.g. storage slot).
        walkable_grid : boolean matrix (True = passable).

        Returns
        -------
        List of (row, col) from start to goal, or None if unreachable.
        """
        rows, cols = walkable_grid.shape
        sr, sc = start
        gr, gc = goal

        if not (0 <= sr < rows and 0 <= sc < cols) or not walkable_grid[sr, sc]:
            return None
        if not (0 <= gr < rows and 0 <= gc < cols):
            return None
        if (sr, sc) == (gr, gc):
            return [(sr, sc)]

        # Manhattan distance heuristic — admissible for 4-connected grid
        def h(r: int, c: int) -> int:
            return abs(r - gr) + abs(c - gc)

        # Priority queue: (f_score, tie_breaker, row, col)
        # tie_breaker ensures FIFO order for equal f-scores
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

            current_g = g_score[(r, c)]
            for dr, dc in directions:
                nr, nc = r + dr, c + dc
                if 0 <= nr < rows and 0 <= nc < cols and walkable_grid[nr, nc]:
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

    def reconstruct_path(self, floor: int, target_row: int, target_col: int) -> list[tuple[int, int]] | None:
        """
        Find shortest path from nearest chariot/elevator to (target_row, target_col)
        using A* search with Manhattan distance heuristic.

        Falls back to BFS distance-map backtracking if A* returns None
        (e.g. walkability changed since pre-computation).
        """
        wg = self.walkable[floor]

        # Find the nearest chariot position (by pre-computed BFS distance)
        d = self.distance_from_chariot[floor]
        if d[target_row, target_col] == -1:
            return None

        # Pick the chariot exit that gives shortest distance to target
        best_start = None
        best_dist = float("inf")
        for cr, cc in self.chariot_positions[floor]:
            dist = d[target_row, target_col]  # pre-computed min distance
            # Compute actual distance from this specific chariot
            chariot_d = self._bfs_distance((cr, cc), wg)
            cd = chariot_d[target_row, target_col]
            if 0 <= cd < best_dist:
                best_dist = cd
                best_start = (cr, cc)

        if best_start is None:
            return None

        # Run A* from best chariot to target
        # A* needs target to be walkable (or adjacent walkable cell)
        # Storage slots (type=1) may not be walkable, so temporarily allow target
        temp_walkable = wg.copy()
        temp_walkable[target_row, target_col] = True

        path = self._astar(best_start, (target_row, target_col), temp_walkable)

        if path is not None:
            return path

        # Fallback: backtrack through pre-computed BFS distance map
        path = [(target_row, target_col)]
        current = (target_row, target_col)
        current_dist = d[current[0], current[1]]
        while current_dist > 0:
            cr, cc = current
            for nr, nc in [(cr - 1, cc), (cr + 1, cc), (cr, cc - 1), (cr, cc + 1)]:
                if 0 <= nr < d.shape[0] and 0 <= nc < d.shape[1]:
                    if d[nr, nc] == current_dist - 1:
                        path.append((nr, nc))
                        current = (nr, nc)
                        current_dist -= 1
                        break
        path.reverse()
        return path

    # ═══════════════════════════════════════════════════════════════════
    # PUBLIC — Utilization Stats
    # ═══════════════════════════════════════════════════════════════════

    def get_utilization(self) -> dict:
        """Return per-floor and total utilization stats."""
        stats: dict = {}
        for floor in [1, 2, 3, 4]:
            floor_slots = [(k, v) for k, v in self.slot_meta.items() if k[0] == floor]
            total_cap = sum(v["total_capacity_m3"] for _, v in floor_slots)
            used = sum(v["used_m3"] for _, v in floor_slots)
            full = sum(1 for _, v in floor_slots if v["remaining_m3"] <= 0)
            stats[floor] = {
                "slots": len(floor_slots),
                "full": full,
                "total_m3": total_cap,
                "used_m3": used,
                "pct": 100 * used / total_cap if total_cap > 0 else 0,
            }
        total_cap = sum(s["total_m3"] for s in stats.values())
        total_used = sum(s["used_m3"] for s in stats.values())
        stats["total"] = {
            "total_m3": total_cap,
            "used_m3": total_used,
            "pct": 100 * total_used / total_cap if total_cap > 0 else 0,
        }
        return stats

    # ═══════════════════════════════════════════════════════════════════
    # PUBLIC — Visualization
    # ═══════════════════════════════════════════════════════════════════

    def visualize(
        self,
        result: dict,
        save_path: str | Path | None = None,
        show: bool = True,
    ) -> plt.Figure:
        """
        Draw a 2-panel figure:
          Left  — Floor layout with path overlay (chariot → target slot)
          Right — Distance heatmap for that floor

        Parameters
        ----------
        result : dict returned by find_best_slot().
        save_path : if provided, save figure to this path.
        show : if True, call plt.show() (set False for headless usage).

        Returns
        -------
        matplotlib Figure object.
        """
        if result is None:
            raise ValueError("No result to visualize (result is None)")

        floor = result["floor"]
        path = result["path"]
        r_target, c_target = result["position"]
        emp_code = result["emplacement_code"]
        cost = result["cost"]
        walk_d = result["walk_distance"]
        elevator_cost = result.get("elevator_cost", floor * self.ASCEND_COST_PER_FLOOR)
        total_dist = result.get("total_distance", elevator_cost + walk_d)
        pid = result["product_id"]
        abc = result["abc_class"]
        vol = result["product_volume_m3"]
        remaining = result["remaining_capacity_m3"]

        t = self.floor_matrices[floor]["type"]

        fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(22, 9))

        # ── Left panel: floor layout + path ──
        ax1.imshow(t, cmap=self.CMAP, vmin=0, vmax=4, interpolation="nearest", alpha=0.6)

        if path:
            pr = [p[0] for p in path]
            pc = [p[1] for p in path]
            ax1.plot(pc, pr, "yo-", linewidth=3, markersize=7, markeredgecolor="black", label="Walk path")
            ax1.plot(pc[0], pr[0], "r*", markersize=25, markeredgecolor="black", markeredgewidth=2, label="Chariot exit")
            ax1.plot(pc[-1], pr[-1], "g^", markersize=20, markeredgecolor="black", markeredgewidth=2, label=f"Target: {emp_code}")

        ax1.set_title(
            f"Product {pid} [{abc}] → Floor {floor}\n"
            f"Slot: {emp_code} | Cost: {cost:.4f}\n"
            f"Journey: Ground(0) ──elevator({elevator_cost}m)──▶ Floor {floor} "
            f"──walk({walk_d}m)──▶ {emp_code}  │  Total: {total_dist}m",
            fontsize=10,
            fontweight="bold",
        )
        ax1.set_xlabel("Column")
        ax1.set_ylabel("Row")
        ax1.legend(loc="upper right", fontsize=9)
        ax1.set_xticks(np.arange(-0.5, t.shape[1], 1), minor=True)
        ax1.set_yticks(np.arange(-0.5, t.shape[0], 1), minor=True)
        ax1.grid(which="minor", color="gray", linestyle="-", linewidth=0.2, alpha=0.3)

        # legend for cell types
        legend_elements = [
            mpatches.Patch(facecolor="white", label="Aisle (0)", edgecolor="black"),
            mpatches.Patch(color="lightblue", label="Storage (1)"),
            mpatches.Patch(color="lightgreen", label="Elevator (2)"),
            mpatches.Patch(color="red", label="Chariot (3)"),
            mpatches.Patch(color="black", label="Obstacle (4)"),
        ]
        ax1.legend(handles=legend_elements + ax1.get_legend_handles_labels()[0][:3],
                   loc="upper right", fontsize=7)

        # ── Right panel: distance heatmap ──
        d_map = self.distance_from_chariot[floor].copy().astype(float)
        d_map[d_map == -1] = np.nan
        im = ax2.imshow(d_map, cmap="RdYlGn_r", interpolation="nearest")
        ax2.set_title(f"BFS Distance Heatmap — Floor {floor}", fontsize=12, fontweight="bold")
        ax2.set_xlabel("Column")
        ax2.set_ylabel("Row")
        plt.colorbar(im, ax=ax2, label="Distance from chariot (m)")

        # Mark chariot positions
        for cr, cc in self.chariot_positions[floor]:
            ax2.plot(cc, cr, "rx", markersize=15, markeredgewidth=3)

        # Mark target
        ax2.plot(c_target, r_target, "g^", markersize=16, markeredgecolor="black", markeredgewidth=2)

        ax2.set_xticks(np.arange(-0.5, t.shape[1], 1), minor=True)
        ax2.set_yticks(np.arange(-0.5, t.shape[0], 1), minor=True)
        ax2.grid(which="minor", color="gray", linestyle="-", linewidth=0.2, alpha=0.3)

        fig.suptitle("Warehouse Storage Assignment — Path & Distance", fontsize=14, fontweight="bold")
        plt.tight_layout()

        if save_path:
            fig.savefig(save_path, dpi=150, bbox_inches="tight")

        if show:
            plt.show()

        return fig

    def visualize_all_floors(
        self,
        save_path: str | Path | None = None,
        show: bool = True,
    ) -> plt.Figure:
        """Draw all 4 floor layouts side-by-side (useful for overview)."""
        fig, axes = plt.subplots(2, 2, figsize=(18, 14))
        fig.suptitle("Warehouse Floor Layouts", fontsize=16, fontweight="bold")

        for idx, floor in enumerate([1, 2, 3, 4]):
            ax = axes[idx // 2, idx % 2]
            t = self.floor_matrices[floor]["type"]
            ax.imshow(t, cmap=self.CMAP, vmin=0, vmax=4, interpolation="nearest")
            ax.set_title(f"Floor {floor}", fontsize=14, fontweight="bold")
            # Mark chariot
            for cr, cc in self.chariot_positions[floor]:
                ax.plot(cc, cr, "r*", markersize=15, markeredgecolor="black")
            ax.set_xlabel("Column")
            ax.set_ylabel("Row")

        legend_elements = [
            mpatches.Patch(color="white", label="Aisle (0)", edgecolor="black"),
            mpatches.Patch(color="lightblue", label="Storage (1)"),
            mpatches.Patch(color="lightgreen", label="Elevator (2)"),
            mpatches.Patch(color="red", label="Chariot (3)"),
            mpatches.Patch(color="black", label="Obstacle (4)"),
        ]
        fig.legend(handles=legend_elements, loc="lower center", ncol=5, bbox_to_anchor=(0.5, -0.02))
        plt.tight_layout()

        if save_path:
            fig.savefig(save_path, dpi=150, bbox_inches="tight")
        if show:
            plt.show()
        return fig

    def visualize_walkability(self, floor: int) -> plt.Figure:
        """Show walkability grid for a single floor."""
        w = self.walkable[floor]
        fig, ax = plt.subplots(figsize=(12, 9))
        ax.imshow(w.astype(int), cmap="Greens", interpolation="nearest")
        ax.set_title(f"Walkability — Floor {floor} (green = walkable)", fontsize=13, fontweight="bold")
        pct = 100 * np.sum(w) / w.size
        ax.set_xlabel(f"Walkable: {np.sum(w)}/{w.size} ({pct:.1f}%)")
        plt.tight_layout()
        plt.show()
        return fig

    # ═══════════════════════════════════════════════════════════════════
    # PUBLIC — Pretty-print result
    # ═══════════════════════════════════════════════════════════════════

    def print_result(self, result: dict | None):
        """Pretty-print an assignment result to the console."""
        if result is None:
            print("❌ No suitable slot found for this product.")
            return

        feat = self.product_features.get(result["product_id"], {})
        floor = result['floor']
        elevator_cost = result.get('elevator_cost', floor * self.ASCEND_COST_PER_FLOOR)
        total_dist = result.get('total_distance', elevator_cost + result['walk_distance'])

        print("=" * 70)
        print("  STORAGE ASSIGNMENT RESULT")
        print("=" * 70)
        print(f"  Product ID:        {result['product_id']}")
        print(f"  Product Name:      {feat.get('nom', 'N/A')}")
        print(f"  Category:          {feat.get('categorie', 'N/A')}")
        print(f"  ABC Class:         {result['abc_class']}")
        print(f"  Volume:            {result['product_volume_m3']} m³")
        print(f"  Weight:            {feat.get('weight_kg', 'N/A')} kg")
        print(f"  Demand Frequency:  {feat.get('demand_freq', 0)}")
        print(f"  Receipt Frequency: {feat.get('reception_freq', 0)}")
        print("-" * 70)
        print(f"  Assigned Slot:     {result['emplacement_code']}")
        print(f"  Floor:             {floor}")
        print(f"  Grid Position:     row={result['position'][0]}, col={result['position'][1]}")
        print(f"  Placement Cost:    {result['cost']:.4f}")
        print(f"  Remaining Cap.:    {result['remaining_capacity_m3']:.1f} m³")
        print("-" * 70)
        print("  FULL JOURNEY:")
        print(f"    1. Ground Floor (0) — Receiving zone")
        print(f"    2. Chariot elevator: Floor 0 → Floor {floor}")
        print(f"       Elevator cost:  {elevator_cost} m  "
              f"({floor} floors × {self.ASCEND_COST_PER_FLOOR} m/floor)")
        print(f"    3. Walk on Floor {floor}: chariot exit → slot {result['emplacement_code']}")
        print(f"       Walk distance:  {result['walk_distance']} m  ({len(result['path'] or [])} steps)")
        print(f"    ─────────────────────────────────")
        print(f"    TOTAL DISTANCE:    {total_dist} m  (elevator + walk)")
        print("-" * 70)
        if result["path"]:
            print(f"  Walk path on Floor {floor} ({len(result['path'])} cells):")
            path_str = " → ".join(f"({r},{c})" for r, c in result["path"])
            while len(path_str) > 65:
                cut = path_str[:65].rfind("→")
                if cut == -1:
                    break
                print(f"    {path_str[:cut+1]}")
                path_str = path_str[cut + 2:]
            print(f"    {path_str}")
        else:
            print("  Walk path: ⚠ could not reconstruct")
        print("=" * 70)

    def print_batch_results(self, results: list[dict | None]):
        """Pretty-print batch MILP optimization results."""
        assigned = [r for r in results if r is not None]
        failed = len(results) - len(assigned)

        print("=" * 78)
        print("  BATCH OPTIMIZATION RESULTS  (MILP — Mixed Integer Linear Programming)")
        print("=" * 78)
        print(f"  Products requested:     {len(results)}")
        print(f"  Successfully assigned:  {len(assigned)}")
        if failed:
            print(f"  Failed / infeasible:    {failed}")
        if assigned:
            total_cost = sum(r["cost"] for r in assigned)
            avg_cost = total_cost / len(assigned)
            print(f"  Total placement cost:   {total_cost:.4f}")
            print(f"  Average cost:           {avg_cost:.4f}")

            # Per-floor distribution
            floor_counts: dict[int, int] = {}
            for r in assigned:
                floor_counts[r["floor"]] = floor_counts.get(r["floor"], 0) + 1
            dist_str = ", ".join(f"Floor {f}: {n}" for f, n in sorted(floor_counts.items()))
            print(f"  Floor distribution:     {dist_str}")

            # ABC distribution
            abc_counts: dict[str, int] = {}
            for r in assigned:
                abc_counts[r["abc_class"]] = abc_counts.get(r["abc_class"], 0) + 1
            abc_str = ", ".join(f"{k}: {v}" for k, v in sorted(abc_counts.items()))
            print(f"  ABC distribution:       {abc_str}")

        print("-" * 78)
        print(f"  {'#':<4} {'Product ID':<22} {'ABC':<5} {'Floor':<6} "
              f"{'Slot':<16} {'Cost':<10} {'Total Dist':<11} {'Vol(m³)':<10}")
        print("-" * 78)
        for i, r in enumerate(results):
            if r is None:
                print(f"  {i+1:<4} {'— INFEASIBLE —':<22}")
                continue
            print(
                f"  {i+1:<4} {r['product_id'][:20]:<22} {r['abc_class']:<5} "
                f"{r['floor']:<6} {r['emplacement_code']:<16} "
                f"{r['cost']:<10.4f} {r['total_distance']:<11} "
                f"{r['product_volume_m3']:<10.4f}"
            )
        print("=" * 78)

    # ═══════════════════════════════════════════════════════════════════
    # PUBLIC — Convenience: assign + print + visualize in one call
    # ═══════════════════════════════════════════════════════════════════

    def assign_product(
        self,
        product_id: str,
        update_capacity: bool = False,
        visualize: bool = True,
        save_fig: str | None = None,
        show: bool = True,
    ) -> dict | None:
        """
        End-to-end: find best slot, print result, optionally visualize.

        Parameters
        ----------
        product_id : ID from produits.csv.
        update_capacity : commit the assignment (deduct volume).
        visualize : draw the path figure.
        save_fig : if set, save figure to this file path.
        show : if True, call plt.show() (set False for headless/save-only).

        Returns
        -------
        Assignment result dict, or None.
        """
        result = self.find_best_slot(product_id, update_capacity=update_capacity)
        self.print_result(result)

        if result and visualize:
            self.visualize(result, save_path=save_fig, show=show)

        return result

    def list_products(self, limit: int = 20):
        """Print a summary table of available products."""
        print(f"{'PID':<40} {'Name':<30} {'Class':<6} {'Vol(m³)':<10} {'Demand':<10}")
        print("-" * 96)
        for i, (pid, f) in enumerate(self.product_features.items()):
            if i >= limit:
                print(f"... and {len(self.product_features) - limit} more")
                break
            print(f"{pid:<40} {str(f['nom'])[:28]:<30} {f['abc_class']:<6} "
                  f"{f['volume_m3']:<10.4f} {f['demand_freq']:<10.0f}")


# ═══════════════════════════════════════════════════════════════════════
# CLI ENTRY POINT
# ═══════════════════════════════════════════════════════════════════════

def main():
    parser = argparse.ArgumentParser(
        description="Warehouse Storage Optimizer — Find the best slot for a product"
    )
    parser.add_argument(
        "--product-id", "-p",
        type=str,
        default=None,
        help="Product ID to assign (from produits.csv). If omitted, lists available products.",
    )
    parser.add_argument(
        "--data-dir", "-d",
        type=str,
        default=None,
        help="Path to the data folder (with Book1.csv, etc.). Defaults to script directory.",
    )
    parser.add_argument(
        "--save-fig", "-s",
        type=str,
        default=None,
        help="Save the visualization figure to this file (e.g. output.png).",
    )
    parser.add_argument(
        "--commit",
        action="store_true",
        help="Actually deduct volume from slot capacity (default: preview only).",
    )
    parser.add_argument(
        "--list-products",
        action="store_true",
        help="List available product IDs and exit.",
    )
    parser.add_argument(
        "--no-viz",
        action="store_true",
        help="Skip the visualization (text output only).",
    )
    parser.add_argument(
        "--alpha", type=float, default=0.8, help="Cost weight for receipt distance (default: 0.8)"
    )
    parser.add_argument(
        "--beta", type=float, default=3.5, help="Cost weight for demand×expedition distance (default: 3.5)"
    )
    parser.add_argument(
        "--delta", type=float, default=0.7, help="Cost weight for reception×receipt distance (default: 0.7)"
    )
    parser.add_argument(
        "--product-ids",
        type=str,
        nargs="+",
        default=None,
        help="Multiple product IDs for batch MILP optimization (e.g. --product-ids ID1 ID2 ID3).",
    )

    args = parser.parse_args()

    print("⏳ Building warehouse model (loading data, computing BFS distances)...")
    optimizer = WarehouseOptimizer(
        data_dir=args.data_dir,
        alpha=args.alpha,
        beta=args.beta,
        delta=args.delta,
    )
    print(f"✓ Ready — {len(optimizer.product_features)} products, "
          f"{len(optimizer.slot_meta)} storage cells across 4 floors\n")

    if args.list_products:
        optimizer.list_products(limit=50)
        return

    # ── Batch MILP optimization ──
    if args.product_ids:
        print("🔧 Running batch MILP optimization ...")
        results = optimizer.optimize_batch_assignment(
            args.product_ids,
            update_capacity=args.commit,
        )
        optimizer.print_batch_results(results)
        if not args.no_viz:
            for r in results:
                if r is not None:
                    optimizer.visualize(r, save_path=args.save_fig, show=True)
        return

    if args.product_id is None:
        print("No --product-id provided. Here are some available products:\n")
        optimizer.list_products(limit=15)
        print("\nRe-run with:  python storage_assignment.py --product-id <ID>")
        return

    do_viz = (not args.no_viz) or (args.save_fig is not None)
    do_show = not args.no_viz  # only pop up window if --no-viz is NOT set
    result = optimizer.assign_product(
        product_id=args.product_id,
        update_capacity=args.commit,
        visualize=do_viz,
        save_fig=args.save_fig,
        show=do_show,
    )

    if result is None:
        print(f"\n⚠ Product '{args.product_id}' not found or no slot available.")
        print("Use --list-products to see valid product IDs.")


if __name__ == "__main__":
    main()
