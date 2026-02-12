import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:wms/data/database/database_helper.dart';
// import 'package:internet_connection_checker/internet_connection_checker.dart'; // Optional for more robust check

class SyncService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Singleton pattern
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  /// Checks if the device has internet connection
  Future<bool> get isOnline async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      return false;
    }
    // Optional: Check actual internet access with InternetConnectionChecker
    // return await InternetConnectionChecker().hasConnection;
    return true;
  }

  /// Syncs local changes to the remote server
  Future<void> syncLocalToRemote() async {
    if (!(await isOnline)) return;

    print("Starting sync: Local -> Remote");

    final db = await _dbHelper.database;
    // Example: Get unsynced tasks
    final List<Map<String, dynamic>> unsyncedTasks = await db.query(
      'tasks',
      where: 'is_synced = ?',
      whereArgs: [0],
    );

    for (var taskMap in unsyncedTasks) {
      try {
        // TODO: Call your Remote API here to save the task
        // await apiService.updateTask(taskMap);

        // If successful, mark as synced locally
        await db.update(
          'tasks',
          {'is_synced': 1},
          where: 'id = ?',
          whereArgs: [taskMap['id']],
        );
      } catch (e) {
        print("Failed to sync task ${taskMap['id']}: $e");
      }
    }
  }

  /// Syncs remote changes to the local database
  Future<void> syncRemoteToLocal() async {
    if (!(await isOnline)) return;

    print("Starting sync: Remote -> Local");

    try {
      // TODO: Call Remote API to get latest data
      // final remoteTasks = await apiService.getTasks();

      // Update local DB
      // for (var task in remoteTasks) {
      //   await db.insert('tasks', task.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      // }
    } catch (e) {
      print("Failed to pull data from remote: $e");
    }
  }
}
