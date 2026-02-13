import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wms/core/database/app_database.dart';
import 'package:drift/drift.dart';

class ReceiptRepository {
  final SupabaseClient _supabase;
  final AppDatabase _db;

  ReceiptRepository(this._supabase, this._db);

  /// Fetch incoming command orders from Supabase
  Future<List<Map<String, dynamic>>> getIncomingOrders() async {
    final response = await _supabase
        .from('command_orders')
        .select('''
          *,
          command_order_lines (
            id,
            id_produit,
            quantite_attendue,
            produits (sku, nom_produit)
          )
        ''')
        .eq('statut', 'PENDING');
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// Submit a receipt confirmation to the local sync queue
  Future<void> confirmReceipt({
    required String orderId,
    required List<Map<String, dynamic>> receivedItems,
  }) async {
    // 1. Add to local sync queue
    await _db.into(_db.syncQueue).insert(
      SyncQueueCompanion(
        actionType: const Value('CONFIRM_RECEIPT'),
        payload: Value(jsonEncode({
          'order_id': orderId,
          'received_items': receivedItems,
        })),
        timestamp: Value(DateTime.now()),
        status: const Value('pending'),
      ),
    );

    // 2. Optionally update local task status if it exists
    // (Search for a task related to this order)
  }
}
