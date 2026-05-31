"""
Generate ground floor visualizations for presentation.

Creates colored plots of ground floor (Floor 0):
- Type matrix with shelves, exhibition zones, VRAC, etc.
- Walkability grid
- Shelf and exhibition target locations

Saves as high-resolution PNG files.
"""
import sys
from pathlib import Path
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.colors import ListedColormap
import numpy as np

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent / "routeOpt"))
from route_optimizer import RouteOptimizer


def visualize_ground_floor(output_dir: Path = None):
    """Generate ground floor visualizations."""
    
    if output_dir is None:
        output_dir = Path(__file__).parent / "presentation_figures"
    output_dir.mkdir(exist_ok=True)
    
    print("🏗️  Building route optimizer (includes ground floor)...")
    optimizer = RouteOptimizer()
    print(f"✓ Loaded ground floor data\n")
    
    # ═══════════════════════════════════════════════════════════════
    # 1. Ground Floor Type Matrix
    # ═══════════════════════════════════════════════════════════════
    print("📊 Generating ground floor type matrix...")
    
    # Color scheme for ground floor
    gf_colors = [
        "#FFFFFF",   # 0 = Aisle (white)
        "#8B4513",   # 1 = Shelf (brown)
        "#FFD700",   # 2 = Elevator (gold)
        "#00BFFF",   # 3 = Chariot (deep sky blue)
        "#333333",   # 4 = Obstacle (dark gray)
        "#90EE90",   # 5 = VRAC (light green)
        "#FF69B4",   # 6 = Exhibition (hot pink)
        "#FF4500",   # 7 = Bureau (orange red)
    ]
    labels = ["Aisle", "Shelf", "Elevator", "Chariot", "Obstacle", "VRAC", "Exhibition", "Bureau"]
    
    fig, ax = plt.subplots(1, 1, figsize=(16, 12))
    type_matrix = optimizer.floor_matrices[0]["type"]
    
    cmap = ListedColormap(gf_colors)
    im = ax.imshow(type_matrix, cmap=cmap, origin="upper", vmin=0, vmax=7)
    ax.set_title("Ground Floor (Floor 0) - Type Matrix", fontsize=14, fontweight="bold")
    ax.set_xlabel(f"Columns (width: {type_matrix.shape[1]})")
    ax.set_ylabel(f"Rows (height: {type_matrix.shape[0]})")
    
    # Add legend
    patches = [mpatches.Patch(color=gf_colors[i], label=labels[i]) 
               for i in range(len(labels))]
    ax.legend(handles=patches, loc="upper right", fontsize=10, framealpha=0.9)
    
    # Add statistics
    unique, counts = np.unique(type_matrix, return_counts=True)
    stats_text = "Cell Counts:\n"
    for val, count in zip(unique, counts):
        if val < len(labels):
            pct = (count / type_matrix.size) * 100
            stats_text += f"{labels[val]}: {count} ({pct:.1f}%)\n"
    
    ax.text(0.02, 0.02, stats_text.strip(), 
            transform=ax.transAxes, fontsize=9, verticalalignment='bottom',
            bbox=dict(boxstyle='round', facecolor='white', alpha=0.9))
    
    plt.tight_layout()
    output_path = output_dir / "5_ground_floor_type_matrix.png"
    plt.savefig(output_path, dpi=300, bbox_inches='tight')
    print(f"  ✓ Saved: {output_path}")
    plt.close()
    
    # ═══════════════════════════════════════════════════════════════
    # 2. Ground Floor Walkability
    # ═══════════════════════════════════════════════════════════════
    print("🚶 Generating ground floor walkability...")
    
    fig, ax = plt.subplots(1, 1, figsize=(16, 12))
    walk_matrix = optimizer.walkability[0]
    
    walk_cmap = ListedColormap(["#FF4444", "#44FF44"])  # red=blocked, green=walkable
    im = ax.imshow(walk_matrix, cmap=walk_cmap, origin="upper", vmin=0, vmax=1)
    ax.set_title("Ground Floor - Walkability Grid", fontsize=14, fontweight="bold")
    ax.set_xlabel("Columns")
    ax.set_ylabel("Rows")
    
    # Add legend
    patches = [
        mpatches.Patch(color="#FF4444", label="Blocked"),
        mpatches.Patch(color="#44FF44", label="Walkable")
    ]
    ax.legend(handles=patches, loc="upper right", fontsize=10, framealpha=0.9)
    
    # Statistics
    total_cells = walk_matrix.size
    walkable_cells = np.sum(walk_matrix)
    blocked_cells = total_cells - walkable_cells
    walkable_pct = (walkable_cells / total_cells) * 100
    
    stats_text = f"Walkable: {walkable_cells} ({walkable_pct:.1f}%)\n"
    stats_text += f"Blocked: {blocked_cells} ({100-walkable_pct:.1f}%)\n"
    stats_text += f"Total: {total_cells}"
    
    ax.text(0.02, 0.98, stats_text, 
            transform=ax.transAxes, fontsize=10, verticalalignment='top',
            bbox=dict(boxstyle='round', facecolor='white', alpha=0.9))
    
    plt.tight_layout()
    output_path = output_dir / "6_ground_floor_walkability.png"
    plt.savefig(output_path, dpi=300, bbox_inches='tight')
    print(f"  ✓ Saved: {output_path}")
    plt.close()
    
    # ═══════════════════════════════════════════════════════════════
    # 3. Ground Floor Targets (Shelves & Exhibition)
    # ═══════════════════════════════════════════════════════════════
    print("🎯 Generating ground floor targets...")
    
    fig, ax = plt.subplots(1, 1, figsize=(16, 12))
    
    # Base layer - type matrix with transparency
    im = ax.imshow(type_matrix, cmap=cmap, origin="upper", vmin=0, vmax=7, alpha=0.3)
    
    # Overlay shelf targets
    for shelf_id, shelf_data in optimizer.shelf_targets.items():
        shelf_cells = shelf_data["cells"]
        access_points = shelf_data["access_points"]
        
        # Plot shelf cells
        for (r, c) in shelf_cells:
            ax.plot(c, r, 's', color='brown', markersize=4, alpha=0.7)
        
        # Plot access points
        for (r, c) in access_points:
            ax.plot(c, r, 'o', color='blue', markersize=3, alpha=0.6)
    
    # Overlay exhibition targets
    for exh_data in optimizer.exhibition_targets:
        exh_cells = exh_data["cells"]
        access_points = exh_data["access_points"]
        
        # Plot exhibition cells
        for (r, c) in exh_cells:
            ax.plot(c, r, '^', color='magenta', markersize=4, alpha=0.7)
        
        # Plot access points
        for (r, c) in access_points:
            ax.plot(c, r, 'o', color='cyan', markersize=3, alpha=0.6)
    
    ax.set_title("Ground Floor - Target Locations", fontsize=14, fontweight="bold")
    ax.set_xlabel("Columns")
    ax.set_ylabel("Rows")
    
    # Custom legend
    legend_elements = [
        mpatches.Patch(color='brown', label=f'Shelves ({len(optimizer.shelf_targets)} total)'),
        mpatches.Patch(color='blue', label='Shelf Access Points'),
        mpatches.Patch(color='magenta', label=f'Exhibition ({len(optimizer.exhibition_targets)} zones)'),
        mpatches.Patch(color='cyan', label='Exhibition Access Points'),
    ]
    ax.legend(handles=legend_elements, loc="upper right", fontsize=10, framealpha=0.9)
    
    # Statistics
    total_shelves = len(optimizer.shelf_targets)
    total_exhibitions = len(optimizer.exhibition_targets)
    stats_text = f"Shelves: {total_shelves}\n"
    stats_text += f"Exhibition Zones: {total_exhibitions}"
    
    ax.text(0.02, 0.98, stats_text, 
            transform=ax.transAxes, fontsize=10, verticalalignment='top',
            bbox=dict(boxstyle='round', facecolor='white', alpha=0.9))
    
    plt.tight_layout()
    output_path = output_dir / "7_ground_floor_targets.png"
    plt.savefig(output_path, dpi=300, bbox_inches='tight')
    print(f"  ✓ Saved: {output_path}")
    plt.close()
    
    # ═══════════════════════════════════════════════════════════════
    # Summary
    # ═══════════════════════════════════════════════════════════════
    print(f"\n✅ Ground floor visualizations saved to: {output_dir}")
    print(f"\nGenerated files:")
    print(f"  5. Ground floor type matrix")
    print(f"  6. Ground floor walkability")
    print(f"  7. Ground floor targets (shelves & exhibition)")
    
    return output_dir


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Generate ground floor visualizations")
    parser.add_argument(
        "--output-dir", "-o",
        type=str,
        default=None,
        help="Output directory for figures (default: ./presentation_figures)"
    )
    
    args = parser.parse_args()
    
    output_dir = Path(args.output_dir) if args.output_dir else None
    visualize_ground_floor(output_dir)
