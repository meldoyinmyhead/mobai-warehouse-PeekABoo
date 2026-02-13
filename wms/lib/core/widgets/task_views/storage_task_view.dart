import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/features/logistics/data/models/task_model.dart';
import 'package:wms/features/supervisor/presentation/widgets/isometric_warehouse_painter.dart';
import 'package:wms/core/data/warehouse_layout_data.dart';
import 'package:wms/core/theme/app_theme.dart';
import 'package:wms/core/widgets/task_views/flag.dart';

class StorageTaskView extends StatefulWidget {
  final TaskModel task;

  const StorageTaskView({super.key, required this.task});

  @override
  State<StorageTaskView> createState() => _StorageTaskViewState();
}

class _StorageTaskViewState extends State<StorageTaskView> {
  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitToScreen();
    });
  }

  void _fitToScreen() {
    if (!mounted) return;
    
    final floor = widget.task.locationData['floor'] ?? 'N2';
    final layout = WarehouseLayoutData.getAllFloors()[floor] ?? [];
    if (layout.isEmpty) return;
    
    int rows = layout.length;
    int cols = layout[0].length;
    
    // Isometric width roughly
    double contentWidth = (rows + cols) * 32.0; 
    double screenWidth = MediaQuery.of(context).size.width;
    
    // Scale to fit width, but not too small
    double scale = (screenWidth / contentWidth) * 0.9;
    scale = scale.clamp(0.1, 1.5);

    final Matrix4 matrix = Matrix4.identity()
      ..translate(screenWidth / 2, 50.0) // Center horizontally
      ..scale(scale);
      
    _transformationController.value = matrix;
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailsCard(),
        const SizedBox(height: 20),
        _buildLocationAssignmentCard(),
        const SizedBox(height: 20),
        _buildNavigationMapCard(),
        const SizedBox(height: 20),
        _buildCurrentLocationCard(),
        const SizedBox(height: 32),
        _buildActionButtons(context),
      ],
    );
  }

  Widget _buildDetailsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Détails de stockage',
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        _buildDetailRow('Produit:', widget.task.details['product'] ?? 'Appareils électroniques - Téléphones mobiles'),
        const Divider(height: 20),
        _buildDetailRow('Quantité:', '${widget.task.details['quantity'] ?? '50'} unités'),
        const Divider(height: 20),
        _buildDetailRow('Poids:', widget.task.details['weight'] ?? '25kg'),
        const Divider(height: 20),
        _buildDetailRow('Dimensions:', widget.task.details['dimensions'] ?? '40x30x25cm'),
      ],
    );
  }

  Widget _buildLocationAssignmentCard() {
    final zone = widget.task.locationData['zone'] ?? 'B7';
    final floor = widget.task.locationData['floor'] ?? 'N2';
    final slot = widget.task.locationData['slot'] ?? 'C5';
    final locationCode = '$zone-$floor-$slot';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attribution de l\'emplacement',
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.lightBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.lightBlue.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppTheme.lightBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on, size: 28, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emplacement de stockage attribué',
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      locationCode,
                      style: GoogleFonts.lato(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkBlue,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Étage: $floor • Emplacement: $slot',
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationMapCard() {
    final floor = widget.task.locationData['floor'] ?? 'N2';
    
    // Mock Path for Storage (Receiving -> Slot)
    final List<Offset> mockPath = [
       const Offset(0, 0), // Entry
       const Offset(0, 5),
       const Offset(5, 5),
       const Offset(5, 8),
    ];

    // Mock Employee at start of path
    final List<Map<String, dynamic>> entities = [
      {'x': 0.0, 'y': 0.0, 'color': AppTheme.lightBlue, 'label': 'MOI', 'type': 'employee'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Carte de navigation',
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['0A', 'N1', 'N2', 'N3', 'N4'].map((f) {
            final isSelected = f == floor;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.lightBlue : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      f,
                      style: GoogleFonts.lato(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Container(
          height: 300, // Increased height for map
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                InteractiveViewer(
                  transformationController: _transformationController,
                  maxScale: 5.0,
                  minScale: 0.1,
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  constrained: false,
                  child: SizedBox(
                    width: 1500,
                    height: 1500,
                    child: CustomPaint(
                      painter: IsometricWarehousePainter(
                        layout: WarehouseLayoutData.getAllFloors()[floor] ?? [],
                        entities: entities,
                        aiPath: mockPath,
                      ),
                    ),
                  ),
                ),
                // Overlay text
                Positioned(
                  top: 10,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        'Carte interactive: Zoomez pour voir les détails',
                        style: GoogleFonts.lato(
                          fontSize: 10,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentLocationCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.green.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.my_location, color: AppTheme.green, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emplacement actuel: ${widget.task.details['current_location'] ?? 'Zone de réception'}',
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppTheme.green,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Suivez le chemin en surbrillance pour atteindre ${widget.task.locationData['zone'] ?? 'B7'}-${widget.task.locationData['floor'] ?? 'N2'}-${widget.task.locationData['slot'] ?? 'C5'}',
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(
              'Confirmer le stockage',
              style: GoogleFonts.lato(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FlagIssueScreen(taskId: widget.task.id),
              ),
            );
            },
            icon: const Icon(Icons.flag_outlined, color: Colors.white, size: 20),
            label: Text(
              'Signaler un problème',
              style: GoogleFonts.lato(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.lato(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.lato(
                fontWeight: FontWeight.w600,
                color: color ?? Colors.black87,
                fontSize: 13,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}