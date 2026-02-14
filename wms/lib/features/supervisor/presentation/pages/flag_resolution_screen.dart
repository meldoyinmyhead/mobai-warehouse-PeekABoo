import 'package:flutter/material.dart';
import 'package:wms/features/logistics/data/models/task_model.dart';
// Assuming User model has name/id

class FlagResolutionScreen extends StatelessWidget {
  final TaskModel task; // The flagged task
  const FlagResolutionScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resolve Issue 🚩')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Issue Details
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reported By: ${task.assignedTo}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Issue Type: Damaged Product'), // Needs real data from task/flag model
                    const SizedBox(height: 8),
                    const Text('Notes: Box appeared crushed on corner.'),
                    const SizedBox(height: 12),
                    // Placeholder for image
                    Container(
                      height: 150,
                      color: Colors.grey.shade300,
                      child: const Center(child: Icon(Icons.image, size: 50, color: Colors.grey)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            const Text('Resolution Action', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            ListTile(
              leading: const Icon(Icons.person_add, color: Colors.blue),
              title: const Text('Reassign Task'),
              onTap: () {},
              tileColor: Colors.grey.shade100,
            ),
            const SizedBox(height: 8),
             ListTile(
              leading: const Icon(Icons.inventory, color: Colors.orange),
              title: const Text('Update Inventory (Mark Damaged)'),
              onTap: () {},
              tileColor: Colors.grey.shade100,
            ),
             const SizedBox(height: 8),
             ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Mark Resolved (False Alarm)'),
              onTap: () {},
              tileColor: Colors.grey.shade100,
            ),
            const SizedBox(height: 8),
             ListTile(
              leading: const Icon(Icons.admin_panel_settings, color: Colors.purple),
              title: const Text('Escalate to Admin'),
              onTap: () {},
              tileColor: Colors.grey.shade100,
            ),
          ],
        ),
      ),
    );
  }
}
