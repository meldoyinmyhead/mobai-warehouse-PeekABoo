import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/core/theme/app_theme.dart';
import 'package:wms/features/warehouse/presentation/widgets/isometric_warehouse_painter.dart';
import 'package:wms/core/widgets/supervisorBottonBar.dart';

import 'package:wms/features/warehouse/data/warehouse_layout_data.dart';

class SupervisorMapScreen extends StatefulWidget {
  const SupervisorMapScreen({super.key});

  @override
  State<SupervisorMapScreen> createState() => _SupervisorMapScreenState();
}

class _SupervisorMapScreenState extends State<SupervisorMapScreen> {
  String _selectedFloor = '0A';
  final List<String> _floors = ['0A', 'N1', 'N2', 'N3', 'N4'];
  late Map<String, List<List<int>>> _floorLayouts;
  bool _showEntities = true;
  bool _showPaths = true;
  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    _floorLayouts = WarehouseLayoutData.getAllFloors();
    // Schedule fit to screen after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitToScreen();
    });
  }

  void _fitToScreen() {
    if (!mounted) return;
    
    // Default Isometric warehouse size estimation
    // 32.0 is tile size
    // We can estimate the bounding box.
    // Width ~= (rows + cols) * 32.0
    // Height ~= (rows + cols) * 16.0
    
    final layout = _floorLayouts[_selectedFloor] ?? [];
    if (layout.isEmpty) return;
    
    int rows = layout.length;
    int cols = layout[0].length;
    
    // Isometric width/height roughly
    double contentWidth = (rows + cols) * 32.0; 
    // double contentHeight = (rows + cols) * 16.0;

    double screenWidth = MediaQuery.of(context).size.width;
    double scale = screenWidth / contentWidth;
    
    // Add some padding
    scale = scale * 0.9;
    
    // Clamp scale
    scale = scale.clamp(0.1, 2.0);

    final Matrix4 matrix = Matrix4.identity()
      ..translate(screenWidth / 2, 100.0) // Center horizontally, some top padding
      ..scale(scale);
      
    // Adjust translation to center the isometric view
    // The painter centers at (width/2, height/5). 
    // We just need to reset zoom to a reasonable level that fits the width.
    _transformationController.value = matrix;
  }


  // Mock data for live entities
  final List<Map<String, dynamic>> _mockEntities = [
    {'x': 0.0, 'y': 5.0, 'color': AppTheme.lightBlue, 'label': 'EMP-001', 'type': 'employee'}, // Aisle 0
    {'x': 6.0, 'y': 8.0, 'color': AppTheme.yellow, 'label': 'CHR-042', 'type': 'chariot'},   // Center Aisle
    {'x': 2.0, 'y': 15.0, 'color': AppTheme.lightBlue, 'label': 'EMP-007', 'type': 'employee'}, // Aisle 2
  ];

  final List<Offset> _mockPath = [
    const Offset(0, 0),   // Top-left aisle
    const Offset(0, 5),   // Down to aisle
    const Offset(6, 5),   // Across aisle
    const Offset(6, 8),   // Down to elevator area
    const Offset(10, 8),  // Near center
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Dark professional background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Surveillance Entrepôt',
          style: GoogleFonts.lato(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pushReplacementNamed(context, '/supervisor/dashboard'),
        ),
        actions: [
          IconButton(
            icon: Icon(_showEntities ? Icons.person : Icons.person_off, color: AppTheme.lightBlue),
            onPressed: () => setState(() => _showEntities = !_showEntities),
            tooltip: 'Afficher les employés',
          ),
          IconButton(
            icon: Icon(_showPaths ? Icons.route : Icons.route_outlined, color: AppTheme.yellow),
            onPressed: () => setState(() => _showPaths = !_showPaths),
            tooltip: 'Afficher les itinéraires',
          ),
        ],
      ),
      body: Stack(
        children: [
          // The Custom Map
          InteractiveViewer(
            transformationController: _transformationController,
            maxScale: 5.0,
            minScale: 0.1,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            constrained: false, // Allow infinite canvas
            child: SizedBox(
              width: 2000, // Large canvas for the map
              height: 2000,
              child: CustomPaint(
                painter: IsometricWarehousePainter(
                  layout: _floorLayouts[_selectedFloor] ?? [],
                  entities: _showEntities ? _mockEntities : [],
                  aiPath: _showPaths ? _mockPath : [], floor: '',
                ),
              ),
            ),
          ),

          // Floor Selector Overlay
          Positioned(
            left: 20,
            top: 20,
            child: Column(
              children: _floors.map((floor) {
                final isSelected = _selectedFloor == floor;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedFloor = floor);
                      // Optional: Reset zoom when changing floors?
                      // _fitToScreen(); 
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.lightBlue : Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          floor,
                          style: GoogleFonts.lato(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Legend Overlay
          Positioned(
            right: 20,
            bottom: 40,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                   _buildLegendItem(AppTheme.lightBlue, "Employé"),
                   const SizedBox(height: 8),
                   _buildLegendItem(AppTheme.yellow, "Chariot (CHR)"),
                   const SizedBox(height: 8),
                   _buildLegendItem(AppTheme.mediumGrey, "Stockage (Rack)"),
                   const SizedBox(height: 8),
                   _buildLegendItem(Colors.red.withOpacity(0.5), "Obstacle"),
                   const SizedBox(height: 8),
                   _buildLegendItem(AppTheme.lightBlue.withOpacity(0.5), "Ascenseur (Pers)"),
                   const SizedBox(height: 8),
                   _buildLegendItem(AppTheme.yellow.withOpacity(0.5), "Ascenseur (Chariot)"),
                ],
              ),
            ),
          ),

          // Live Indicator
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.circle, color: Colors.white, size: 8),
                  const SizedBox(width: 8),
                  Text(
                    'LIVE',
                    style: GoogleFonts.lato(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SupervisorBottomBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, '/supervisor/dashboard');
          if (index == 2) Navigator.pushReplacementNamed(context, '/supervisor/ai_review');
        },
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.lato(fontSize: 11, color: Colors.black87),
        ),
      ],
    );
  }
}
