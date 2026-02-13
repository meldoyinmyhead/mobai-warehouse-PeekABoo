import 'package:flutter/material.dart';
import 'package:wms/features/warehouse/data/models/task_model.dart';
import 'package:wms/features/warehouse/presentation/widgets/task_views/receipt_task_view.dart';
import 'package:wms/features/warehouse/presentation/widgets/task_views/storage_task_view.dart';
import 'package:wms/features/warehouse/presentation/widgets/task_views/picking_task_view.dart';
import 'package:wms/features/warehouse/presentation/widgets/task_views/delivery_task_view.dart';

class EmployeeTaskDetailScreen extends StatelessWidget {
  final TaskModel task;

  const EmployeeTaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Match design background
      appBar: AppBar(
        title: Text('${task.title} Task'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.help_outline), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _buildTaskView(),
      ),
    );
  }

  Widget _buildTaskView() {
    switch (task.type) {
      case TaskType.receipt:
        return ReceiptTaskView(task: task);
      case TaskType.storage:
        return StorageTaskView(task: task);
      case TaskType.picking:
        return PickingTaskView(task: task);
      case TaskType.delivery:
        return DeliveryTaskView(task: task);
      default:
        return Center(child: Text('Unknown task type: ${task.type}'));
    }
  }
}
