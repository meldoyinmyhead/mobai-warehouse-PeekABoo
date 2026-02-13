import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wms/features/warehouse/data/models/ai_override_model.dart';

class AiReviewRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch all orders pending AI validation
  Future<List<Map<String, dynamic>>> getPendingAiOrders() async {
    // 1. Get Pending Review Preparation Orders
    final prepResponse = await _supabase
        .from('preparation_orders')
        .select('''
          *,
          preparation_order_lines (
            id,
            quantite_ai,
            produits (sku, nom_produit)
          )
        ''')
        .eq('statut', 'PENDING_REVIEW');

    // 2. Get Pending Review Picking Orders
    final pickResponse = await _supabase
        .from('picking_orders')
        .select('''
          *,
          picking_order_stops (
            stop_sequence,
            quantite,
            produits (sku, nom_produit)
          )
        ''')
        .eq('statut', 'PENDING_REVIEW');

    // Combine and format for the UI
    List<Map<String, dynamic>> orders = [];

    for (var p in prepResponse) {
      orders.add({
        'id': p['id'],
        'reference': p['reference'],
        'type': AiOrderType.preparation,
        'product': p['preparation_order_lines']?.isNotEmpty == true 
            ? p['preparation_order_lines'][0]['produits']['nom_produit'] 
            : 'Multi-produits',
        'ai_quantity': p['preparation_order_lines']?.isNotEmpty == true
            ? p['preparation_order_lines'][0]['quantite_ai']
            : 0,
        'status': p['statut'],
        'created_at': p['created_at'],
      });
    }

    for (var p in pickResponse) {
      orders.add({
        'id': p['id'],
        'reference': p['reference'],
        'type': AiOrderType.picking,
        'product': 'Ordre de Picking',
        'route_distance': p['route_distance_m'],
        'status': p['statut'],
        'created_at': p['created_at'],
      });
    }

    return orders;
  }

  Future<void> approveOrder(String orderId, AiOrderType type) async {
    final table = type == AiOrderType.preparation ? 'preparation_orders' : 'picking_orders';
    await _supabase
        .from(table)
        .update({'statut': 'APPROVED'})
        .eq('id', orderId);
  }

  Future<void> saveOverride(AiOverrideModel override) async {
    await _supabase
        .from('ai_overrides')
        .insert(override.toMap());
        
    // Also update the original order status
    final table = override.orderType == AiOrderType.preparation ? 'preparation_orders' : 'picking_orders';
    await _supabase
        .from(table)
        .update({'statut': 'OVERRIDDEN'})
        .eq('id', override.orderId);
  }
}
