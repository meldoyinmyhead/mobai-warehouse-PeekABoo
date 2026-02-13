abstract class IAdminDashboard {
  Future<void> approveUser(String userId);
  Future<void> assignTask(String taskId, String userId);
  Future<void> viewSystemStats();
}
