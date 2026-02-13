import 'package:flutter/material.dart';
import 'package:wms/features/warehouse/data/models/task_model.dart';
// Determine if we can add this dependency later, for now just UI

class DeliveryTaskView extends StatelessWidget {
  final TaskModel task;

  const DeliveryTaskView({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailsCard(),
        const SizedBox(height: 16),
        _buildDestinationCard(),
        const SizedBox(height: 16),
        _buildProductList(),
         const SizedBox(height: 16),
        _buildConfirmationCard(),
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
            const Text('Delivery Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            _buildDetailRow('Order Number:', task.description.replaceAll('Order: ', '')),
            _buildDetailRow('Delivery Type:', task.details['delivery_type'] ?? 'N/A'),
            _buildDetailRow('Loading Bay:', task.details['loading_bay'] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Column(
        children: [
           Padding(
             padding: const EdgeInsets.all(16.0),
             child: Row(
               children: [
                 const Icon(Icons.location_on, color: Color(0xFF006D84), size: 32),
                 const SizedBox(width: 16),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(task.details['destination'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                       Text(task.details['address'] ?? '', style: const TextStyle(color: Color(0xFF434343))),
                     ],
                   )
                 )
               ],
             ),
           ),
           Container(
             width: double.infinity,
             padding: const EdgeInsets.all(16),
             color: const Color(0xFF006D84).withOpacity(0.05),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                  _buildDetailRow('Contact Person:', task.details['contact_person'] ?? 'N/A'),
                   GestureDetector(
                     onTap: () {
                       // Launch dialer
                     },
                     child: Text(
                       task.details['contact_number'] ?? 'N/A', 
                       style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)
                     ),
                   ),
               ],
             ),
           ),
           Padding(
             padding: const EdgeInsets.all(16),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 const Text('Estimated Delivery Time', style: TextStyle(fontWeight: FontWeight.bold)),
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                   decoration: BoxDecoration(color: const Color(0xFFF4F2F2), borderRadius: BorderRadius.circular(8)),
                   child: Text(task.details['estimated_time'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                 )
               ],
             ),
           )
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Product List', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          ...task.products.map((product) => Column(
            children: [
              ListTile(
                 title: Text(product.name),
                 trailing: Text('${product.expectedQuantity} units', style: const TextStyle(color: Color(0xFF006D84), fontWeight: FontWeight.bold)),
              ),
              const Divider(height: 1),
            ],
          )),
        ],
      )
    );
  }
  
  Widget _buildConfirmationCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             const Text('Delivery Confirmation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
             const SizedBox(height: 16),
             _buildDetailRow('Delivery Timestamp', '11:45 PM - Feb 12, 2026'), // Mock/Current time
              const SizedBox(height: 16),
             const Text('Recipient Name/Signature', style: TextStyle(fontWeight: FontWeight.w500)),
             const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Enter recipient name...',
                  filled: true,
                  fillColor: const Color(0xFFF4F2F2),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Optional - Digital signature or recipient confirmation', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              const Text('Delivery Notes (Optional)', style: TextStyle(fontWeight: FontWeight.w500)),
             const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Add any delivery notes...',
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
            child: const Text('Confirm Delivery', style: TextStyle(color: Colors.white, fontSize: 16)),
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
