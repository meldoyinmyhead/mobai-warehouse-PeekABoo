import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wms/features/supervisor/data/models/ai_override_model.dart';

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
    
    print('DEBUG: Prep Response: $prepResponse');

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
    
    print('DEBUG: Pick Response: $pickResponse');

    // Combine and format for the UI
    List<Map<String, dynamic>> orders = [];
    final random = DateTime.now().millisecondsSinceEpoch; // Simple seed

    for (var p in prepResponse) {
      orders.add({
        'id': p['id'],
        'reference': p['reference'],
        'type': AiOrderType.preparation,
        'product': (p['preparation_order_lines']?.isNotEmpty == true && 
                    p['preparation_order_lines'][0]['produits'] != null) 
            ? '${p['preparation_order_lines'][0]['produits']['sku'] ?? 'SKU?'} - ${p['preparation_order_lines'][0]['produits']['nom_produit'] ?? 'Produit?'}' 
            : 'Multi-produits',
        'sku': (p['preparation_order_lines']?.isNotEmpty == true && 
                    p['preparation_order_lines'][0]['produits'] != null) 
            ? p['preparation_order_lines'][0]['produits']['sku'] ?? 'SKU-000'
            : 'SKU-MIXED',
        'product_name': (p['preparation_order_lines']?.isNotEmpty == true && 
                    p['preparation_order_lines'][0]['produits'] != null) 
            ? p['preparation_order_lines'][0]['produits']['nom_produit'] ?? 'Produit Inconnu'
            : 'Multi-produits',
        'ai_quantity': p['preparation_order_lines']?.isNotEmpty == true
            ? (p['preparation_order_lines'][0]['quantite_ai'] ?? 0)
            : 0,
        'status': p['statut'],
        'created_at': p['created_at'],
        // Mock Data for UI Design
        'confidence': 85 + (p['reference'].hashCode % 14), // 85-98%
        'forecast_date': DateTime.now().add(const Duration(days: 1)),
        'reasoning': "Historical sales data indicates a 20% spike in demand for this SKU next week due to seasonal trends.",
      });
    }

    for (var p in pickResponse) {
      orders.add({
        'id': p['id'],
        'reference': p['reference'],
        'type': AiOrderType.picking,
        'product': (p['picking_order_stops']?.isNotEmpty == true && 
                    p['picking_order_stops'][0]['produits'] != null)
             ? p['picking_order_stops'][0]['produits']['nom_produit'] ?? 'Produit Inconnu'
             : 'Ordre de Picking',
        'sku': (p['picking_order_stops']?.isNotEmpty == true && 
                    p['picking_order_stops'][0]['produits'] != null)
             ? p['picking_order_stops'][0]['produits']['sku'] ?? 'SKU-000'
             : 'SKU-ROUTE',
         'product_name': (p['picking_order_stops']?.isNotEmpty == true && 
                    p['picking_order_stops'][0]['produits'] != null)
             ? p['picking_order_stops'][0]['produits']['nom_produit'] ?? 'Produit Inconnu'
             : 'Optimisation de Route',
        'route_distance': p['route_distance_m'],
        'status': p['statut'],
        'created_at': p['created_at'],
        // Mock Data
        'confidence': 88 + (p['reference'].hashCode % 11), // 88-98%
        'forecast_date': DateTime.now(),
        'reasoning': "Route optimization reduced travel distance by 15% compared to standard FIFO allocation.",
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
