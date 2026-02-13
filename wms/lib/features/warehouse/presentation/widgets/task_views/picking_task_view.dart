import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/features/warehouse/data/models/task_model.dart';
import 'package:wms/features/warehouse/presentation/widgets/isometric_warehouse_painter.dart';

class PickingTaskView extends StatelessWidget {
  final TaskModel task;

  const PickingTaskView({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailsCard(),
        const SizedBox(height: 24),
        Text('Products to Pick', style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF004D40))),
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
        Text('Picking Details', style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF004D40))),
        const SizedBox(height: 12),
        _buildDetailRow('Order Number:', task.id),
        _buildDetailRow('Order Type:', task.details['order_type'] ?? 'Customer Order'),
        _buildPriorityRow(),
        _buildDetailRow('Start Location:', task.locationData['start_location'] ?? 'Packing Area'),
      ],
    );
  }

  Widget _buildPriorityRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Priority:', style: GoogleFonts.lato(color: Colors.grey[600], fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFEF5350), borderRadius: BorderRadius.circular(6)),
            child: Text(
              'HIGH',
              style: GoogleFonts.lato(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsToPickList() {
    return Column(
      children: task.products.asMap().entries.map((entry) {
        final index = entry.key + 1;
        final product = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(color: Color(0xFFFFD600), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text('$index', style: GoogleFonts.lato(color: const Color(0xFF004D40), fontSize: 14, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF004D40))),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('A3-N1-C${index + 7}', style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Quantity needed:', style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[600])),
                        Text('${product.expectedQuantity} units', style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 12, color: const Color(0xFF004D40))),
                      ],
                    )
                  ],
                )
              )
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExecutionCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Picking Execution', style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF004D40))),
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
              floor: '0A',
              entities: [],
              aiPath: [], // Show picking route
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Confirm Picked Quantities', style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF004D40))),
        const SizedBox(height: 16),
        ...task.products.map((product) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(product.name, style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey[800])),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Expected: ${product.expectedQuantity}',
                  hintStyle: GoogleFonts.lato(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                  suffixText: 'units',
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
          height: 60,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00796B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Complete Picking', style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.flag, color: Colors.white),
            label: Text('Flag Issue', style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF5350),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.lato(color: Colors.grey[600], fontSize: 14)),
          Text(value, style: GoogleFonts.lato(fontWeight: FontWeight.bold, color: const Color(0xFF004D40), fontSize: 14)),
        ],
      ),
    );
  }
}
