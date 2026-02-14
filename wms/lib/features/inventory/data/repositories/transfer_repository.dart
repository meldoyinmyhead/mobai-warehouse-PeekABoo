import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wms/core/database/app_database.dart';
import 'package:drift/drift.dart';

class TransferRepository {
  final SupabaseClient _supabase;
  final AppDatabase _db;

  TransferRepository(this._supabase, this._db);

  /// Fetch local stock for a product to confirm availability
  Future<int> getLocalStock(String productId, String locationId) async {
    final result = await (_db.select(_db.localInventory)
      ..where((tbl) => tbl.productId.equals(productId) & tbl.locationId.equals(locationId)))
      .getSingleOrNull();
    return result?.quantity ?? 0;
  }

  /// Submit a transfer to the local sync queue
  Future<void> submitTransfer({
    required String productId,
    required String fromLocationId,
    required String toLocationId,
    required int quantity,
  }) async {
    await _db.into(_db.syncQueue).insert(
      SyncQueueCompanion(
        actionType: const Value('TRANSFER_STOCK'),
        payload: Value(jsonEncode({
          'product_id': productId,
          'from_location_id': fromLocationId,
          'to_location_id': toLocationId,
          'quantity': quantity,
        })),
        timestamp: Value(DateTime.now()),
      ),
    );
    
    // Optimistic local update
    await _db.into(_db.localInventory).insertOnConflictUpdate(
      LocalInventoryCompanion(
        productId: Value(productId),
        locationId: Value(fromLocationId),
        quantity: Value((await getLocalStock(productId, fromLocationId)) - quantity),
      ),
    );
  }
}
