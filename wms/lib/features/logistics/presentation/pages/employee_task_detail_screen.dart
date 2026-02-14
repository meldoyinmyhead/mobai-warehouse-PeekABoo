import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/core/theme/app_theme.dart';
import 'package:wms/features/logistics/data/models/task_model.dart';
import 'package:wms/features/supervisor/presentation/widgets/isometric_warehouse_painter.dart';
import 'package:wms/core/data/warehouse_layout_data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms/features/logistics/presentation/cubits/employee_task_cubit.dart';

class EmployeeMapTaskScreen extends StatefulWidget {
  final TaskModel task;

  const EmployeeMapTaskScreen({super.key, required this.task});

  @override
  State<EmployeeMapTaskScreen> createState() => _EmployeeMapTaskScreenState();
}

class _EmployeeMapTaskScreenState extends State<EmployeeMapTaskScreen> {
  late Map<String, List<List<int>>> _floorLayouts;
  String _currentFloor = '0A'; // Default, should be dynamic based on task
  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    _floorLayouts = WarehouseLayoutData.getAllFloors();
    
    // Determine floor from first point if available
    if (widget.task.aiPathData.isNotEmpty) {
      // Map Z to floor string? Assuming direct mapping 0->0A, 1->N1, etc.
      // For now just checking if z > 0
      if (widget.task.aiPathData.first.z == 1) _currentFloor = 'N1';
       if (widget.task.aiPathData.first.z == 2) _currentFloor = 'N2';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitToScreen();
    });
  }

  void _fitToScreen() {
    if (!mounted) return;
    
    final layout = _floorLayouts[_currentFloor] ?? [];
    if (layout.isEmpty) return;
    
    int rows = layout.length;
    int cols = layout[0].length;
    double contentWidth = (rows + cols) * 32.0; 
    double screenWidth = MediaQuery.of(context).size.width;
    double scale = screenWidth / contentWidth;
    scale = scale.clamp(0.2, 2.0);

    final Matrix4 matrix = Matrix4.identity()
      ..translate(screenWidth / 2, 100.0)
      ..scale(scale);
      
    _transformationController.value = matrix;
  }

  @override
  Widget build(BuildContext context) {
    // Convert LocationPointModel to Offset for painter
    // Note: Painter expects x,y as 'p','q' indices
    final List<Offset> pathOffsets = widget.task.aiPathData.map((pt) {
       return Offset(pt.x, pt.y);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.task.title, style: GoogleFonts.lato(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // 1. Map View
          Expanded(
            flex: 3,
            child: Container(
              color: const Color(0xFF1A1A1A),
              child: Stack(
                children: [
                  InteractiveViewer(
                    transformationController: _transformationController,
                     maxScale: 5.0,
                    minScale: 0.1,
                    boundaryMargin: const EdgeInsets.all(double.infinity),
                    constrained: false,
                    child: SizedBox(
                      width: 2000,
                      height: 2000,
                      child: CustomPaint(
                        painter: IsometricWarehousePainter(
                          layout: _floorLayouts[_currentFloor] ?? [],
                          floor: _currentFloor,
                          aiPath: pathOffsets,
                          entities: [
                            // Show current user position (start of path)
                            if (pathOffsets.isNotEmpty)
                              {'x': pathOffsets.first.dx, 'y': pathOffsets.first.dy, 'color': AppTheme.lightBlue, 'label': 'Moi', 'type': 'employee'}
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration( color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                      child: Text("Étage: $_currentFloor", style: const TextStyle(color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
          ),
          
          // 2. Task Details / Steps
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text("Route Optimisée (${widget.task.details['distance'] ?? 0} m)", 
                     style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkBlue)),
                   const SizedBox(height: 10),
                   Expanded(
                     child: ListView.builder(
                       itemCount: widget.task.aiPathData.length, // Or products
                       itemBuilder: (context, index) {
                         final pt = widget.task.aiPathData[index];
                         final product = index < widget.task.products.length ? widget.task.products[index] : null;
                         
                         return ListTile(
                           leading: CircleAvatar(
                             backgroundColor: AppTheme.lightBlue.withOpacity(0.1),
                             child: Text("${index + 1}", style: const TextStyle(color: AppTheme.lightBlue, fontWeight: FontWeight.bold)),
                           ),
                           title: Text(product?.name ?? "Emplacement ${pt.locId}"),
                           subtitle: Text("Loc: ${pt.locId} (R${pt.y.toInt()}-C${pt.x.toInt()})"),
                           trailing: product != null 
                              ? Text("${product.expectedQuantity} pcs", style: const TextStyle(fontWeight: FontWeight.bold))
                              : null,
                         );
                       },
                     ),
                   ),
                   SizedBox(
                     width: double.infinity,
                     child: ElevatedButton.icon(
                       icon: const Icon(Icons.check),
                       label: const Text("Terminer la Tâche"),
                       style: ElevatedButton.styleFrom(
                         backgroundColor: AppTheme.green,
                         foregroundColor: Colors.white,
                         padding: const EdgeInsets.symmetric(vertical: 12),
                       ),
                       onPressed: () async {
                          // Complete task logic
                          try {
                            // Check if Cubit is available, otherwise use Repository directly?
                            // Assuming Cubit is available for now. 
                            // If fail, we might need to fix Router or Provider.
                            await context.read<EmployeeTaskCubit>().completeTask(widget.task.id);
                            
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Tâche terminée avec succès!")),
                              );
                              Navigator.pop(context);
                            }
                          } catch (e) {
                             if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Erreur: $e")),
                              );
                            }
                          }
                       },
                     ),
                   )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
