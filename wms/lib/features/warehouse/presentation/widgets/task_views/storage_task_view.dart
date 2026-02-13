import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/features/warehouse/data/models/task_model.dart';
import 'package:wms/features/warehouse/presentation/widgets/isometric_warehouse_painter.dart';

class StorageTaskView extends StatelessWidget {
  final TaskModel task;

  const StorageTaskView({super.key, required this.task});

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
        Text('Storage Details', style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF004D40))),
        const SizedBox(height: 12),
        _buildDetailRow('Product:', task.details['product'] ?? 'N/A'),
        _buildDetailRow('Quantity:', '${task.details['quantity']} units'),
        _buildDetailRow('Weight:', task.details['weight'] ?? 'N/A'),
        _buildDetailRow('Dimensions:', task.details['dimensions'] ?? 'N/A'),
      ],
    );
  }

  Widget _buildLocationAssignmentCard() {
    final zone = task.locationData['zone'] ?? 'N/A';
    final floor = task.locationData['floor'] ?? 'N/A';
    final slot = task.locationData['slot'] ?? 'N/A';
    final locationCode = '$zone-$floor-$slot';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Location Assignment', style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey[700])),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 36, color: Color(0xFF00796B)),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Assigned Storage Location', style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[600])),
                    Text(locationCode, style: GoogleFonts.lato(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFF004D40))),
                    Text('Floor: $floor • Slot: $slot', style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[600])),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNavigationMapCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Navigation Map', style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF004D40))),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['0A', 'N1', 'N2', 'N3', 'N4'].map((f) => 
            GestureDetector(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: f == task.locationData['floor'] ? const Color(0xFF004D40) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(f, style: GoogleFonts.lato(color: f == task.locationData['floor'] ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
              ),
            )
          ).toList(),
        ),
        const SizedBox(height: 16),
        Container(
          height: 250,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          clipBehavior: Clip.antiAlias,
          child: CustomPaint(
            size: const Size(double.infinity, 250),
            painter: IsometricWarehousePainter(
              floor: task.locationData['floor'] ?? '0A',
              entities: [], // Map entity for current location?
              aiPath: [], // Highlight path to destination
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentLocationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.explore_outlined, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Location: ${task.details['current_location'] ?? 'Receiving Area'}', style: GoogleFonts.lato(fontWeight: FontWeight.bold, color: Colors.green[900])),
                Text('Follow the highlighted path to reach ${task.locationData['zone']}-${task.locationData['floor']}-${task.locationData['slot']}', style: GoogleFonts.lato(fontSize: 12, color: Colors.green[800])),
              ],
            ),
          )
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
              backgroundColor: const Color(0xFF006D84),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Confirm Storage', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.flag, color: Colors.white),
            label: const Text('Flag Issue', style: TextStyle(color: Colors.white, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF83737),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF434343))),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color ?? const Color(0xFF232323))),
        ],
      ),
    );
  }
}
