import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms/features/warehouse/presentation/cubits/supervisor/ai_review_cubit.dart';
import 'package:wms/features/warehouse/data/models/ai_override_model.dart';

class AiReviewScreen extends StatelessWidget {
  const AiReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('AI Suggestions Review', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: BlocBuilder<AiReviewCubit, AiReviewState>(
        builder: (context, state) {
          if (state is AiReviewLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is AiReviewLoaded) {
            if (state.pendingOrders.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                    SizedBox(height: 16),
                    Text('All AI suggestions reviewed!', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.pendingOrders.length,
              itemBuilder: (context, index) {
                final order = state.pendingOrders[index];
                return _buildOrderCard(context, order);
              },
            );
          } else if (state is AiReviewError) {
            return Center(child: Text(state.message));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order) {
    bool isPrep = order['type'] == AiOrderType.preparation;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text('AI DRAFT', style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                Text(order['id'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            Text(order['product'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (isPrep) ...[
              _buildDataRow('AI Suggestion', '${order['ai_quantity']} units', Colors.teal),
              _buildDataRow('Current Stock', '${order['current_stock']} units', Colors.red),
            ] else ...[
              _buildDataRow('AI Route', (order['ai_route'] as List).join(' → '), Colors.teal),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showOverrideDialog(context, order),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Override'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.read<AiReviewCubit>().approveOrder(order['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[800],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showOverrideDialog(BuildContext context, Map<String, dynamic> order) {
    final TextEditingController justificationController = TextEditingController();
    final TextEditingController quantityController = TextEditingController(text: order['ai_quantity']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Override ${order['id']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Mandatory justification is required for all AI overrides.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            if (order['type'] == AiOrderType.preparation)
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: 'Final Quantity', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
            const SizedBox(height: 12),
            TextField(
              controller: justificationController,
              decoration: const InputDecoration(labelText: 'Justification', hintText: 'Why are you changing this?', border: OutlineInputBorder()),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (justificationController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Justification is required'), backgroundColor: Colors.red));
                return;
              }
              context.read<AiReviewCubit>().overrideOrder(
                orderId: order['id'],
                justification: justificationController.text,
                finalDecision: {
                  'final_quantity': int.tryParse(quantityController.text) ?? order['ai_quantity'],
                },
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm Override'),
          ),
        ],
      ),
    );
  }
}
