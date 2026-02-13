import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/features/warehouse/data/models/task_model.dart';
import 'package:wms/features/warehouse/presentation/widgets/isometric_warehouse_painter.dart';
import 'package:wms/features/warehouse/data/warehouse_layout_data.dart';
import 'package:wms/core/theme/app_theme.dart';
import 'package:wms/features/warehouse/presentation/widgets/task_views/flag.dart';

class PickingTaskView extends StatefulWidget {
  final TaskModel task;

  const PickingTaskView({super.key, required this.task});

  @override
  State<PickingTaskView> createState() => _PickingTaskViewState();
}

class _PickingTaskViewState extends State<PickingTaskView> {
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
    
    // Picking usually happens on floor 0A or specific floors. 
    // For now assuming 0A as per previous code.
    final layout = WarehouseLayoutData.getAllFloors()['0A'] ?? [];
    if (layout.isEmpty) return;
    
    int rows = layout.length;
    int cols = layout[0].length;
    
    double contentWidth = (rows + cols) * 32.0; 
    double screenWidth = MediaQuery.of(context).size.width;
    
    double scale = (screenWidth / contentWidth) * 0.9;
    scale = scale.clamp(0.1, 1.5);

    final Matrix4 matrix = Matrix4.identity()
      ..translate(screenWidth / 2, 50.0) 
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
        const SizedBox(height: 24),
        Text(
          'Produits à préparer',
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildProductsToPickList(),
        const SizedBox(height: 24),
        _buildExecutionCard(),
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
          'Détails de préparation',
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        _buildDetailRow('Numéro de commande:', widget.task.id),
        const Divider(height: 20),
        _buildDetailRow('Type de commande:', widget.task.details['order_type'] ?? 'Commande client'),
        const Divider(height: 20),
        _buildPriorityRow(),
        const Divider(height: 20),
        _buildDetailRow('Emplacement de départ:', widget.task.locationData['start_location'] ?? 'Zone d\'emballage'),
      ],
    );
  }

  Widget _buildPriorityRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Priorité:',
            style: GoogleFonts.lato(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.red,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'HAUTE',
              style: GoogleFonts.lato(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsToPickList() {
    return Column(
      children: widget.task.products.asMap().entries.map((entry) {
        final index = entry.key + 1;
        final product = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppTheme.yellow,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$index',
                  style: GoogleFonts.lato(
                    color: AppTheme.darkBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: GoogleFonts.lato(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          'A3-N1-C${index + 7}',
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Quantité nécessaire:',
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${product.expectedQuantity} unités',
                          style: GoogleFonts.lato(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppTheme.lightBlue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExecutionCard() {
    // Mock Route for Picking
    // Visiting 3 Aisles
    final List<Offset> mockRoute = [
      const Offset(0, 0),
      const Offset(0, 5),
      const Offset(2, 5),
      const Offset(2, 8),
      const Offset(4, 8),
      const Offset(4, 12),
    ];

    // Mock Entities: Employee + Chariot
    final List<Map<String, dynamic>> entities = [
       {'x': 0.0, 'y': 0.0, 'color': AppTheme.lightBlue, 'label': 'MOI', 'type': 'employee'},
       {'x': 0.0, 'y': 1.0, 'color': AppTheme.yellow, 'label': '', 'type': 'chariot'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exécution de préparation',
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 300, // Increased height
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          clipBehavior: Clip.antiAlias,
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
                        layout: WarehouseLayoutData.getAllFloors()['0A']!,
                        entities: entities,
                        aiPath: mockRoute,
                      ),
                    ),
                  ),
                ),
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
                      'Route de préparation optimisée',
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
        const SizedBox(height: 24),
        Text(
          'Confirmer les quantités préparées',
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ...widget.task.products.map((product) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: GoogleFonts.lato(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Attendu: ${product.expectedQuantity}',
                      hintStyle: GoogleFonts.lato(color: Colors.grey[400]),
                      filled: true,
                      fillColor: AppTheme.veryLightGrey,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppTheme.lightBlue),
                      ),
                      suffixText: 'unités',
                      suffixStyle: GoogleFonts.lato(color: Colors.grey[600]),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            )),
      ],
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
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(
              'Terminer la préparation',
              style: GoogleFonts.lato(
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
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
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
                color: Colors.black87,
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