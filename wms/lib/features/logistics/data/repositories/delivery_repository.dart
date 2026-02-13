import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wms/core/database/app_database.dart';
import 'package:drift/drift.dart';

class DeliveryRepository {
  final SupabaseClient _supabase;
  final AppDatabase _db;

  DeliveryRepository(this._supabase, this._db);

  /// Confirm delivery in the local queue
  Future<void> validateDelivery({
    required String orderId,
    required String result, // SUCCESS, PARTIAL, FAILED
    required String notes,
  }) async {
    await _db.into(_db.syncQueue).insert(
      SyncQueueCompanion(
        actionType: const Value('DELIVERY_VALIDATION'),
        payload: Value(jsonEncode({
          'order_id': orderId,
          'result': result,
          'notes': notes,
        })),
        timestamp: Value(DateTime.now()),
      ),
    );
  }
}
