import 'package:wms/features/warehouse/data/models/task_model.dart';
import 'package:wms/features/warehouse/data/models/location_point_model.dart';

abstract class IEmployeeTaskView {
  Future<List<TaskModel>> getAssignedTasks();
  Future<void> updateTaskStatus(String taskId, String status);
  Future<List<LocationPointModel>> getOptimizedPath(String taskId);
}
