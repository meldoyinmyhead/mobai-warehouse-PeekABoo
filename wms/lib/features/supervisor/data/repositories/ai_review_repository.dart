import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart' as drift;
import 'package:http/http.dart' as http;
import 'package:wms/core/app_config.dart';
import 'package:wms/core/database/app_database.dart';
import 'package:wms/features/supervisor/data/models/ai_override_model.dart';

/// Fetches pending AI reviews from FastAPI when online and caches in local DB.
/// When offline: reads from LocalPendingReviews. Approve/override queue to SyncQueue and sync when online.
class AiReviewRepository {
  final AppDatabase _db;
  final String _backendUrl;
  final Connectivity _connectivity = Connectivity();

  AiReviewRepository(this._db, {String? backendUrl})
      : _backendUrl = backendUrl ?? AppConfig.backendUrl;

  Future<bool> get _isOnline async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);
  }

  /// Get pending AI orders: from backend when online (and cache locally), from local DB when offline.
  Future<List<Map<String, dynamic>>> getPendingAiOrders() async {
    if (await _isOnline) {
      try {
        final r = await http
            .get(Uri.parse('$_backendUrl/supervisor/pending-reviews'))
            .timeout(const Duration(seconds: 15));
        if (r.statusCode == 200) {
          final data = jsonDecode(r.body) as Map<String, dynamic>;
          final prepList = data['preparation_orders'] as List? ?? [];
          final pickList = data['picking_orders'] as List? ?? [];
          await _cachePendingReviews(prepList, pickList);
          return _formatOrdersForUi(prepList, pickList);
        }
      } catch (_) {}
    }

    // Offline: read from local cache
    final local = await (_db.select(_db.localPendingReviews)
          ..where((t) => t.status.equals('pending')))
        .get();
    return local.map((row) {
      final m = jsonDecode(row.data) as Map<String, dynamic>;
      return Map<String, dynamic>.from(m);
    }).toList();
  }

  Future<void> _cachePendingReviews(List prepList, List pickList) async {
    final now = DateTime.now();
    for (final o in prepList) {
      final id = o['id']?.toString();
      if (id == null) continue;
      await _db.into(_db.localPendingReviews).insertOnConflictUpdate(
        LocalPendingReviewsCompanion(
          id: drift.Value(id),
          orderType: const drift.Value('preparation'),
          reference: drift.Value(o['reference']?.toString() ?? ''),
          data: drift.Value(jsonEncode(o)),
          status: drift.Value(o['statut']?.toString() ?? 'pending'),
          createdAt: drift.Value(now),
          lastUpdated: drift.Value(now),
          synced: const drift.Value(false),
        ),
      );
    }
    for (final o in pickList) {
      final id = o['id']?.toString();
      if (id == null) continue;
      await _db.into(_db.localPendingReviews).insertOnConflictUpdate(
        LocalPendingReviewsCompanion(
          id: drift.Value(id),
          orderType: const drift.Value('picking'),
          reference: drift.Value(o['reference']?.toString() ?? ''),
          data: drift.Value(jsonEncode(o)),
          status: drift.Value(o['statut']?.toString() ?? 'pending'),
          createdAt: drift.Value(now),
          lastUpdated: drift.Value(now),
          synced: const drift.Value(false),
        ),
      );
    }
  }

  List<Map<String, dynamic>> _formatOrdersForUi(List prepList, List pickList) {
    final orders = <Map<String, dynamic>>[];
    for (final p in prepList) {
      final lines = p['lines'] as List? ?? [];
      final first = lines.isNotEmpty ? lines[0] as Map<String, dynamic>? : null;
      orders.add({
        'id': p['id'],
        'reference': p['reference'],
        'type': AiOrderType.preparation,
        'product': first != null
            ? '${first['sku'] ?? 'SKU?'} - ${first['nom_produit'] ?? 'Produit?'}'
            : 'Multi-produits',
        'sku': first?['sku'] ?? 'SKU-000',
        'product_name': first?['nom_produit'] ?? 'Multi-produits',
        'ai_quantity': first?['quantite_ai'] ?? 0,
        'status': p['statut'],
        'created_at': p['created_at'],
        'confidence': 85,
        'forecast_date': DateTime.now().add(const Duration(days: 1)),
        'reasoning': 'AI forecast based on historical demand.',
      });
    }
    for (final p in pickList) {
      final stops = p['stops'] as List? ?? [];
      final first = stops.isNotEmpty ? stops[0] as Map<String, dynamic>? : null;
      orders.add({
        'id': p['id'],
        'reference': p['reference'],
        'type': AiOrderType.picking,
        'product': first?['nom_produit'] ?? 'Ordre de Picking',
        'sku': first?['sku'] ?? 'SKU-ROUTE',
        'product_name': first?['nom_produit'] ?? 'Optimisation de Route',
        'route_distance': p['route_distance_m'],
        'status': p['statut'],
        'created_at': p['created_at'],
        'confidence': 88,
        'forecast_date': DateTime.now(),
        'reasoning': 'Route optimization minimises travel distance.',
      });
    }
    return orders;
  }

  /// Approve order: online → call backend; offline → queue and update local.
  Future<void> approveOrder(String orderId, AiOrderType type) async {
    if (await _isOnline) {
      try {
        final path = type == AiOrderType.picking
            ? '$_backendUrl/supervisor/picking-orders/$orderId/approve'
            : '$_backendUrl/supervisor/preparation-orders/$orderId/approve';
        final r = await http.post(Uri.parse(path)).timeout(const Duration(seconds: 15));
        if (r.statusCode == 200) {
          await _markLocalReviewStatus(orderId, 'approved');
          return;
        }
      } catch (_) {}
    }

    // Offline: queue for sync and update local
    await _db.into(_db.syncQueue).insert(
      SyncQueueCompanion.insert(
        actionType: 'AI_APPROVE',
        payload: jsonEncode({
          'order_id': orderId,
          'order_type': type.name,
        }),
        timestamp: DateTime.now(),
        status: const drift.Value('pending'),
      ),
    );
    await _markLocalReviewStatus(orderId, 'approved');
  }

  /// Override with justification: online → POST /ai/log-override; offline → queue (justification stored in payload).
  Future<void> saveOverride(AiOverrideModel override) async {
    final payload = {
      'order_type': override.orderType.name.toUpperCase(),
      'order_id': override.orderId,
      'justification': override.justification,
      'original_ai_suggestion': override.aiSuggestion,
      'user_override_value': override.finalDecision,
    };

    if (await _isOnline) {
      try {
        final body = {
          'user_id': override.overriddenBy,
          ...payload,
        };
        final r = await http
            .post(
              Uri.parse('$_backendUrl/ai/log-override'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
            .timeout(const Duration(seconds: 15));
        if (r.statusCode == 200) {
          await _markLocalReviewStatus(override.orderId, 'overridden');
          return;
        }
      } catch (_) {}
    }

    // Offline: queue override (justification and decision stored in SyncQueue)
    await _db.into(_db.syncQueue).insert(
      SyncQueueCompanion.insert(
        actionType: 'AI_OVERRIDE',
        payload: jsonEncode({
          ...payload,
          'user_id': override.overriddenBy,
        }),
        timestamp: DateTime.now(),
        status: const drift.Value('pending'),
      ),
    );
    await _markLocalReviewStatus(override.orderId, 'overridden');
  }

  Future<void> _markLocalReviewStatus(String orderId, String status) async {
    await (_db.update(_db.localPendingReviews)..where((t) => t.id.equals(orderId)))
        .write(LocalPendingReviewsCompanion(
      status: drift.Value(status),
      lastUpdated: drift.Value(DateTime.now()),
    ));
  }
}
