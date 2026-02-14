import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/core/theme/app_theme.dart';

class LayoutConfiguratorScreen extends StatefulWidget {
  const LayoutConfiguratorScreen({super.key});

  @override
  State<LayoutConfiguratorScreen> createState() => _LayoutConfiguratorScreenState();
}

enum CellType { empty, rack, path, blocked }

class _LayoutConfiguratorScreenState extends State<LayoutConfiguratorScreen> {
  static const int gridSize = 12;
  late List<List<CellType>> _grid;

  @override
  void initState() {
    super.initState();
    _grid = List.generate(
      gridSize,
      (_) => List.generate(gridSize, (_) => CellType.empty),
    );
  }

  void _toggleCell(int row, int col) {
    setState(() {
      final current = _grid[row][col];
      switch (current) {
        case CellType.empty:
          _grid[row][col] = CellType.rack;
          break;
        case CellType.rack:
          _grid[row][col] = CellType.path;
          break;
        case CellType.path:
          _grid[row][col] = CellType.blocked;
          break;
        case CellType.blocked:
          _grid[row][col] = CellType.empty;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Physical Layout Map',
          style: GoogleFonts.lato(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Save logic
              Navigator.pop(context);
            },
            child: Text(
              'SAVE',
              style: GoogleFonts.lato(color: AppTheme.lightBlue, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildLegend(),
          const SizedBox(height: 20),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  margin: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.veryLightGrey,
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gridSize,
                    ),
                    itemCount: gridSize * gridSize,
                    itemBuilder: (context, index) {
                      final row = index ~/ gridSize;
                      final col = index % gridSize;
                      return GestureDetector(
                        onTap: () => _toggleCell(row, col),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[200]!),
                            color: _getCellColor(_grid[row][col]),
                          ),
                          child: _getCellIcon(_grid[row][col]),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          _buildInfoPanel(),
        ],
      ),
    );
  }

  Color _getCellColor(CellType type) {
    switch (type) {
      case CellType.empty:
        return Colors.white;
      case CellType.rack:
        return AppTheme.lightBlue;
      case CellType.path:
        return Colors.grey[100]!;
      case CellType.blocked:
        return AppTheme.red.withOpacity(0.1);
    }
  }

  Widget? _getCellIcon(CellType type) {
    if (type == CellType.rack) {
      return const Icon(Icons.storage, size: 10, color: Colors.white);
    }
    if (type == CellType.blocked) {
      return const Icon(Icons.block, size: 10, color: AppTheme.red);
    }
    return null;
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.veryLightGrey,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem('Rack', AppTheme.lightBlue),
          _buildLegendItem('Path', Colors.white, border: true),
          _buildLegendItem('Blocked', AppTheme.red.withOpacity(0.1), icon: Icons.block),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, {bool border = false, IconData? icon}) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: border ? Border.all(color: Colors.grey[300]!) : null,
          ),
          child: icon != null ? Icon(icon, size: 12, color: AppTheme.red) : null,
        ),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.lato(fontSize: 12, color: Colors.black87)),
      ],
    );
  }

  Widget _buildInfoPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Tap grid cells to cycle between Rack, Path, and Blocked zones.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, size: 16, color: AppTheme.lightBlue),
              const SizedBox(width: 8),
              Text(
                'Estimated capacity: 240 units',
                style: GoogleFonts.lato(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.darkBlue),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
