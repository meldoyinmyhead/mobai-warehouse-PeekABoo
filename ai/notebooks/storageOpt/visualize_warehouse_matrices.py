"""
Generate warehouse matrix visualizations for presentation.

Creates colored plots of:
- Type matrices (all floors 0-4)
- Walkability grids (all floors)
- BFS distance maps from chariot elevators

Saves as high-resolution PNG files.
"""
import sys
from pathlib import Path
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.colors import ListedColormap
import numpy as np

# Add parent directory to path to import storage_assignment
sys.path.insert(0, str(Path(__file__).parent))
from storage_assignment import WarehouseOptimizer


def visualize_all_matrices(output_dir: Path = None):
    """Generate all warehouse matrix visualizations."""
    
    if output_dir is None:
        output_dir = Path(__file__).parent / "presentation_figures"
    output_dir.mkdir(exist_ok=True)
    
    print("🏗️  Building warehouse model...")
    optimizer = WarehouseOptimizer()
    print(f"✓ Loaded {len(optimizer.floor_matrices)} storage floors (1-4)\n")
    
    # ═══════════════════════════════════════════════════════════════
    # 1. Type Matrices - Storage Floors (1-4)
    # ═══════════════════════════════════════════════════════════════
    print("📊 Generating type matrices...")
    
    # Color scheme for floor types
    floor_colors = ["#FFFFFF", "#87CEEB", "#FFD700", "#FF6347", "#404040"]  # aisle, storage, elevator, chariot, obstacle
    
    fig, axes = plt.subplots(2, 2, figsize=(14, 12))
    fig.suptitle("Warehouse Storage Floor Type Matrices (Floors 1-4)", fontsize=16, fontweight="bold")
    
    floors_to_plot = [1, 2, 3, 4]
    
    for idx, floor in enumerate(floors_to_plot):
        ax = axes[idx // 2, idx % 2]
        type_matrix = optimizer.floor_matrices[floor]["type"]
        
        # Storage floors - 5 types
        cmap = ListedColormap(floor_colors)
        vmax = 4
        labels = ["Aisle", "Storage", "Elevator", "Chariot", "Obstacle"]
        
        im = ax.imshow(type_matrix, cmap=cmap, origin="upper", vmin=0, vmax=vmax)
        ax.set_title(f"Floor {floor} (Storage)", fontsize=12, fontweight="bold")
        ax.set_xlabel(f"Columns (width: {type_matrix.shape[1]})")
        ax.set_ylabel(f"Rows (height: {type_matrix.shape[0]})")
        
        # Add legend
        patches = [mpatches.Patch(color=floor_colors[i], label=labels[i]) 
                   for i in range(len(labels))]
        ax.legend(handles=patches, loc="upper right", fontsize=8, framealpha=0.9)
    
    plt.tight_layout()
    output_path = output_dir / "1_type_matrices_all_floors.png"
    plt.savefig(output_path, dpi=300, bbox_inches='tight')
    print(f"  ✓ Saved: {output_path}")
    plt.close()
    
    # ═══════════════════════════════════════════════════════════════
    # 2. Walkability Grids
    # ═══════════════════════════════════════════════════════════════
    print("🚶 Generating walkability grids...")
    
    fig, axes = plt.subplots(2, 2, figsize=(14, 12))
    fig.suptitle("Warehouse Walkability Grids (Floors 1-4)", fontsize=16, fontweight="bold")
    
    walk_cmap = ListedColormap(["#FF4444", "#44FF44"])  # red=blocked, green=walkable
    
    for idx, floor in enumerate(floors_to_plot):
        ax = axes[idx // 2, idx % 2]
        walk_matrix = optimizer.walkable[floor]
        
        im = ax.imshow(walk_matrix, cmap=walk_cmap, origin="upper", vmin=0, vmax=1)
        ax.set_title(f"Floor {floor} (Storage)", fontsize=12, fontweight="bold")
        ax.set_xlabel(f"Columns")
        ax.set_ylabel(f"Rows")
        
        # Add legend
        patches = [
            mpatches.Patch(color="#FF4444", label="Blocked"),
            mpatches.Patch(color="#44FF44", label="Walkable")
        ]
        ax.legend(handles=patches, loc="upper right", fontsize=9, framealpha=0.9)
        
        # Add statistics
        total_cells = walk_matrix.size
        walkable_cells = np.sum(walk_matrix)
        walkable_pct = (walkable_cells / total_cells) * 100
        ax.text(0.02, 0.98, f"Walkable: {walkable_pct:.1f}%", 
                transform=ax.transAxes, fontsize=10, verticalalignment='top',
                bbox=dict(boxstyle='round', facecolor='white', alpha=0.8))
    
    plt.tight_layout()
    output_path = output_dir / "2_walkability_grids.png"
    plt.savefig(output_path, dpi=300, bbox_inches='tight')
    print(f"  ✓ Saved: {output_path}")
    plt.close()
    
    # ═══════════════════════════════════════════════════════════════
    # 3. BFS Distance Maps (from Chariot Elevators)
    # ═══════════════════════════════════════════════════════════════
    print("🗺️  Generating BFS distance maps...")
    
    fig, axes = plt.subplots(2, 2, figsize=(14, 12))
    fig.suptitle("BFS Distance Maps from Chariot Elevators (Floors 1-4)", 
                 fontsize=16, fontweight="bold")
    
    floors_upper = [1, 2, 3, 4]
    
    for idx, floor in enumerate(floors_upper):
        ax = axes[idx // 2, idx % 2]
        dist_matrix = optimizer.distance_from_chariot[floor].copy()
        
        # Mask unreachable cells (-1) for better visualization
        masked = np.ma.masked_where(dist_matrix < 0, dist_matrix)
        
        im = ax.imshow(masked, cmap="viridis", origin="upper")
        ax.set_title(f"Floor {floor} - Distance to Chariot", fontsize=12, fontweight="bold")
        ax.set_xlabel("Columns")
        ax.set_ylabel("Rows")
        
        # Add colorbar
        cbar = plt.colorbar(im, ax=ax, fraction=0.046, pad=0.04)
        cbar.set_label("Steps", rotation=270, labelpad=15)
        
        # Mark chariot positions
        chariot_pos = optimizer.chariot_positions.get(floor, [])
        if chariot_pos:
            for (r, c) in chariot_pos:
                ax.plot(c, r, 'r*', markersize=15, markeredgecolor='white', markeredgewidth=1.5)
        
        # Add statistics
        valid_dists = dist_matrix[dist_matrix >= 0]
        if len(valid_dists) > 0:
            min_dist = valid_dists.min()
            max_dist = valid_dists.max()
            mean_dist = valid_dists.mean()
            ax.text(0.02, 0.98, 
                    f"Min: {min_dist}\nMax: {max_dist}\nMean: {mean_dist:.1f}", 
                    transform=ax.transAxes, fontsize=9, verticalalignment='top',
                    bbox=dict(boxstyle='round', facecolor='white', alpha=0.8))
    
    plt.tight_layout()
    output_path = output_dir / "3_bfs_distance_maps.png"
    plt.savefig(output_path, dpi=300, bbox_inches='tight')
    print(f"  ✓ Saved: {output_path}")
    plt.close()
    
    # ═══════════════════════════════════════════════════════════════
    # 4. Storage Slot Metadata Visualization (Capacity Heatmap)
    # ═══════════════════════════════════════════════════════════════
    print("📦 Generating capacity heatmaps...")
    
    fig, axes = plt.subplots(2, 2, figsize=(14, 12))
    fig.suptitle("Storage Slot Capacity Heatmaps (Floors 1-4)", 
                 fontsize=16, fontweight="bold")
    
    for idx, floor in enumerate(floors_upper):
        ax = axes[idx // 2, idx % 2]
        
        # Build capacity matrix
        type_matrix = optimizer.floor_matrices[floor]["type"]
        capacity_matrix = np.zeros_like(type_matrix, dtype=float)
        
        for (fl, r, c), meta in optimizer.slot_meta.items():
            if fl == floor:
                capacity_matrix[r, c] = meta["remaining_m3"]
        
        # Mask non-storage cells
        storage_mask = type_matrix == 1
        masked_capacity = np.ma.masked_where(~storage_mask, capacity_matrix)
        
        im = ax.imshow(masked_capacity, cmap="RdYlGn", origin="upper", vmin=0)
        ax.set_title(f"Floor {floor} - Remaining Capacity (m³)", fontsize=12, fontweight="bold")
        ax.set_xlabel("Columns")
        ax.set_ylabel("Rows")
        
        # Add colorbar
        cbar = plt.colorbar(im, ax=ax, fraction=0.046, pad=0.04)
        cbar.set_label("m³", rotation=0, labelpad=15)
        
        # Statistics
        valid_caps = capacity_matrix[storage_mask]
        if len(valid_caps) > 0:
            total_cap = valid_caps.sum()
            n_slots = len(valid_caps)
            avg_cap = total_cap / n_slots if n_slots > 0 else 0
            ax.text(0.02, 0.98, 
                    f"Total: {total_cap:.0f} m³\nSlots: {n_slots}\nAvg: {avg_cap:.1f} m³", 
                    transform=ax.transAxes, fontsize=9, verticalalignment='top',
                    bbox=dict(boxstyle='round', facecolor='white', alpha=0.8))
    
    plt.tight_layout()
    output_path = output_dir / "4_capacity_heatmaps.png"
    plt.savefig(output_path, dpi=300, bbox_inches='tight')
    print(f"  ✓ Saved: {output_path}")
    plt.close()
    
    # ═══════════════════════════════════════════════════════════════
    # Summary
    # ═══════════════════════════════════════════════════════════════
    print(f"\n✅ All visualizations saved to: {output_dir}")
    print(f"\nGenerated files:")
    print(f"  1. Type matrices (all floors)")
    print(f"  2. Walkability grids")
    print(f"  3. BFS distance maps")
    print(f"  4. Capacity heatmaps")
    
    return output_dir


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Generate warehouse matrix visualizations")
    parser.add_argument(
        "--output-dir", "-o",
        type=str,
        default=None,
        help="Output directory for figures (default: ./presentation_figures)"
    )
    
    args = parser.parse_args()
    
    output_dir = Path(args.output_dir) if args.output_dir else None
    visualize_all_matrices(output_dir)
