import 'package:flutter/material.dart';
import 'package:wms/features/warehouse/data/models/task_model.dart';

class ReceiptTaskView extends StatelessWidget {
  final TaskModel task;

  const ReceiptTaskView({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailsCard(),
        const SizedBox(height: 16),
        const Text('Expected Products', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildProductsList(),
        const SizedBox(height: 16),
        const Text('Receipt Execution', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        _buildExecutionCard(),
         const SizedBox(height: 24),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Receipt Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            _buildDetailRow('Order Number:', task.description.replaceAll('Order: ', '')),
            _buildDetailRow('Supplier:', task.details['supplier'] ?? 'N/A'),
            _buildDetailRow('Expected Arrival:', task.details['expected_arrival'] ?? 'N/A'),
            _buildDetailRow('Status:', 'Pending Inspection', color: const Color(0xFF004251)),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsList() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
        child: Column(
          children: task.products.map((product) => Column(
            children: [
              ListTile(
                title: Text(product.name),
                trailing: Text('${product.expectedQuantity} units', style: const TextStyle(color:  Color(0xFF006D84), fontWeight: FontWeight.bold)),
              ),
              const Divider(height: 1),
            ],
          )).toList(),
      ),
    );
  }

  Widget _buildExecutionCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...task.products.map((product) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Expected: ${product.expectedQuantity}',
                      filled: true,
                      fillColor: const Color(0xFFF4F2F2),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      suffixText: 'units',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            )),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(value: false, onChanged: (v) {}),
                const Text('All products arrived in good condition'),
              ],
            ),
             const SizedBox(height: 16),
            const Text('Notes (Discrepancies)', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: 'Enter any discrepancies or notes...',
                filled: true,
                fillColor: const Color(0xFFF4F2F2),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
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
            child: const Text('Log Task', style: TextStyle(color: Colors.white, fontSize: 16)),
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
