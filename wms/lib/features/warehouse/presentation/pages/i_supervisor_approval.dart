import 'package:wms/features/warehouse/data/models/task_model.dart';

abstract class ISupervisorApproval {
  Future<List<TaskModel>> getPendingApprovals();
  Future<void> approveTask(String taskId);
  Future<void> rejectTask(String taskId, String reason);
}
