import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:wms/core/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:get_it/get_it.dart';

class SyncService {
  final AppDatabase _db = GetIt.I<AppDatabase>();

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
    return true;
  }

  /// Syncs local changes to the remote server
  // Future<void> syncLocalToRemote() async {
  //   if (!(await isOnline)) return;

  //   print("Starting sync: Local -> Remote");

  //   final unsyncedItems = await (_db.select(_db.syncQueue)..where((t) => t.processed.equals(false))).get();

  //   for (var item in unsyncedItems) {
  //     try {
  //       // TODO: Call your Remote API here based on item.actionType and item.payload
        
  //       // If successful, mark as processed locally
  //       await (_db.update(_db.syncQueue)..where((t) => t.id.equals(item.id))).write(
  //         const SyncQueueCompanion(processed: Value(true)),
  //       );
  //     } catch (e) {
  //       print("Failed to sync item ${item.id}: $e");
  //     }
  //   }
  // }

  Future<void> syncRemoteToLocal() async {
    if (!(await isOnline)) return;
    print("Starting sync: Remote -> Local");
    // TODO: Implement remote pull
  }
}
