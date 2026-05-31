# Warehouse Optimization System - Quick Overview

## 🏢 Warehouse Structure

**Two distinct floor types:**
- **Storage Floors (1-4)**: Upper floors for pallet storage
- **Ground Floor (0)**: Contains shelves, exhibition zones, and expedition areas

---

## 📊 Core Data Matrices

### 1. **Type Matrix** (Cell Classification)
Each floor has a grid where every cell is encoded:
```
0 = Aisle (walkable)
1 = Storage slot / Shelf
2 = Elevator
3 = Chariot elevator (vertical transport)
4 = Obstacle (walls, blocked areas)
5-7 = Ground-floor specific (VRAC, Exhibition, Bureau)
```

### 2. **Slot Matrix** (Location Labels)
- **Floors 1-4**: Slot IDs like `A1`, `B7`, `C12` (storage positions)
- **Ground Floor**: Shelf codes like `0A-01-01`, Exhibition zones `EXH-001`

### 3. **Metadata Dictionary** (Capacity & Properties)
For each storage slot `(floor, row, col)`:
- Remaining capacity (m³)
- Emplacement code (e.g., `B07-N2-A1`)
- Storage priority score
- Product assignment log

---

## 🚶 Walkability Grid

**Binary matrix per floor** indicating traversable cells:
- **Upper floors**: Aisles + Chariot elevators = walkable
- **Ground floor**: Aisles + VRAC + Exhibition = walkable
- **Storage slots**: Reachable but not for through-traffic

---

## 🔍 Pathfinding Strategy

### **Two-Phase Approach:**

#### **Phase 1: Storage Assignment (Floors 1-4 → Slot)**
1. **BFS Distance Maps**: Pre-computed from chariot elevators to all slots
2. **Cost Function**:
   ```
   Cost = α·(receipt_distance) 
        + β·(demand_freq)·(expedition_distance)  [β=3.5, highest weight]
        + δ·(reception_freq)·(receipt_distance)
   ```
3. **MILP Optimization**: Assigns products to minimize total cost while respecting capacity

#### **Phase 2: Route Retrieval (Slot → Ground Floor)**
1. **Leg 1**: A* search from storage slot → chariot elevator (same floor)
2. **Leg 2**: Vertical transit (chariot) with fixed cost per floor
3. **Leg 3**: A* search from ground-floor chariot → target shelf/exhibition

---

## 🎯 How They Work Together

```
Product ID → Inventory lookup → Best slot (via cost + BFS)
                                     ↓
                            Update walkability + capacity
                                     ↓
Retrieval request → Find slot location → A* path reconstruction
                                     ↓
                    Complete route: Slot → Chariot → Ground target
```

**Key Insight**: BFS pre-computes distances for fast cost evaluation, A* reconstructs exact paths on-demand.

---

## 📈 Result
- **Optimal placement**: High-demand items near ground, low-volume near elevators
- **Fast retrieval**: Clear path visualization from any storage point to ground
- **Capacity-aware**: No over-allocation, real-time availability tracking
