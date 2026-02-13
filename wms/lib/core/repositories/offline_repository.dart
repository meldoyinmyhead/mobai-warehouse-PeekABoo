import 'package:drift/drift.dart';
import 'package:wms/core/database/app_database.dart';
import 'dart:convert';

class OfflineRepository {
  final AppDatabase _db;

  OfflineRepository(this._db);

  // --- Tasks ---

  Future<List<LocalTask>> getAllTasks() {
    return _db.select(_db.localTasks).get();
  }

  Future<void> saveTask(String id, String type, Map<String, dynamic> data) async {
    await _db.into(_db.localTasks).insertOnConflictUpdate(
      LocalTasksCompanion(
        id: Value(id),
        type: Value(type),
        status: const Value('pending'), // Default
        data: Value(jsonEncode(data)),
        createdAt: Value(DateTime.now()),
        lastUpdated: Value(DateTime.now()),
        syncStatus: const Value('pending_insert'), // New task created offline
      ),
    );
  }

  Future<void> updateTaskStatus(String id, String status) async {
    await (_db.update(_db.localTasks)..where((t) => t.id.equals(id))).write(
      LocalTasksCompanion(
        status: Value(status),
        lastUpdated: Value(DateTime.now()),
        syncStatus: const Value('pending_update'),
      ),
    );
  }

  // --- Sync Queue Actions ---

  Future<void> queueAction(String actionType, Map<String, dynamic> payload) async {
    await _db.into(_db.syncQueue).insert(
      SyncQueueCompanion(
        actionType: Value(actionType),
        payload: Value(jsonEncode(payload)),
        timestamp: Value(DateTime.now()),
        status: const Value('pending'),
      ),
    );
  }
  
  // Example usage for Picking
  Future<void> completePickingStop(String stopId, int qty) async {
    // 1. Queue the action for sync
    await queueAction('COMPLETE_STOP', {
      'stop_id': stopId,
      'qty_picked': qty,
    });
    
    // 2. Update local state if needed (e.g. mark stop as done in local task JSON)
    // complicated logic omitted for brevity, would involve reading task JSON, modifying, saving back.
  }
}
