import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wms/core/database/app_database.dart';
import 'package:drift/drift.dart';

class PickingRepository {
  final SupabaseClient _supabase;
  final AppDatabase _db;

  PickingRepository(this._supabase, this._db);

  /// Fetch picking tasks from local DB
  Future<List<LocalTask>> getPickingTasks() async {
    return await (_db.select(_db.localTasks)
      ..where((tbl) => tbl.type.equals('picking')))
      .get();
  }

  /// Mark a picking stop as complete in the local queue
  Future<void> completeStop({
    required String stopId,
    required int quantityPicked,
  }) async {
    await _db.into(_db.syncQueue).insert(
      SyncQueueCompanion(
        actionType: const Value('COMPLETE_STOP'),
        payload: Value(jsonEncode({
          'stop_id': stopId,
          'qty_picked': quantityPicked,
        })),
        timestamp: Value(DateTime.now()),
      ),
    );

    // Update local status of the stop if tracked in LocalTasks
  }
}
