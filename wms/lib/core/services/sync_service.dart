import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wms/core/database/app_database.dart';
import 'package:wms/core/app_config.dart';
import 'package:drift/drift.dart' as drift;

/// Single source of truth for sync: FastAPI backend for tasks, overrides, approvals.
/// Real-time: connectivity-triggered sync + periodic refresh (no WebSocket on FastAPI).
class SyncService {
  final AppDatabase _db;
  final Connectivity _connectivity;
  final String _backendUrl;
  final String? Function() _getUserId;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _periodicSyncTimer;
  static const Duration _periodicSyncInterval = Duration(seconds: 45);

  SyncService._(
    this._db,
    this._connectivity,
    this._backendUrl,
    this._getUserId,
  );

  static SyncService? _instance;

  static Future<SyncService> init(
    AppDatabase db, {
    String? backendUrl,
    String? Function()? getUserId,
  }) async {
    if (_instance != null) return _instance!;

    final url = backendUrl ?? AppConfig.backendUrl;
    final getUserIdFn = getUserId ?? (() => null);

    _instance = SyncService._(
      db,
      Connectivity(),
      url,
      getUserIdFn,
    );

    // When user signs in (Supabase), run sync. Also support FastAPI-only auth.
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) {
        _instance!.runSync();
      }
    });

    // Connectivity: when back online, run sync (maximise offline score).
    _instance!._listenConnectivity();

    // Periodic sync for real-time feel (tasks + supervisor pending reviews cache).
    _instance!._startPeriodicSync();

    return _instance!;
  }

  void _startPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(_periodicSyncInterval, (_) => runSync());
  }

  void _listenConnectivity() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet);
      if (hasConnection) {
        print('[Sync] Connectivity restored. Running sync.');
        runSync();
      }
    });
  }

  Future<void> runSync() async {
    final results = await _connectivity.checkConnectivity();
    final hasConnection = results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);
    if (!hasConnection) {
      print('[Sync] Offline. Skipping sync.');
      return;
    }

    try {
      print('[Sync] Starting Sync...');
      await _pushPendingActions();
      await _pullLatestData();
      print('[Sync] Sync completed.');
    } catch (e) {
      print('[Sync] Error: $e');
    }
  }

  Future<void> _pushPendingActions() async {
    final pendingActions = await (_db.select(_db.syncQueue)
          ..where((tbl) => tbl.status.equals('pending')))
        .get();

    for (final action in pendingActions) {
      try {
        final payload = jsonDecode(action.payload) as Map<String, dynamic>;
        final userId = _getUserId();

        // Prefer FastAPI backend for task completion, overrides, approvals
        bool synced = false;

        switch (action.actionType) {
          case 'COMPLETE_TASK':
            synced = await _pushCompleteTask(payload);
            break;
          case 'AI_OVERRIDE':
            synced = await _pushLogOverride(payload, userId);
            break;
          case 'AI_APPROVE':
            synced = await _pushApproveOrder(payload);
            break;
          case 'COMPLETE_STOP':
          case 'CONFIRM_RECEIPT':
          case 'TRANSFER_STOCK':
          case 'DELIVERY_VALIDATION':
            // Optional: keep Supabase RPC if you use them; else skip or add FastAPI endpoints
            synced = await _pushViaSupabase(action.actionType, payload);
            break;
        }

        if (synced) {
          await _markActionSynced(action.id);
        }
      } catch (e) {
        print('[Sync] Error pushing action ${action.id}: $e');
      }
    }
  }

  Future<bool> _pushCompleteTask(Map<String, dynamic> payload) async {
    final taskId = payload['task_id'] as String?;
    if (taskId == null) return false;
    try {
      final r = await http.post(
        Uri.parse('$_backendUrl/employee/tasks/$taskId/complete'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _pushLogOverride(Map<String, dynamic> payload, String? userId) async {
    if (userId == null) return false;
    try {
      final body = {
        'user_id': userId,
        'order_type': payload['order_type'],
        'order_id': payload['order_id'],
        'justification': payload['justification'],
        'original_ai_suggestion': payload['original_ai_suggestion'],
        'user_override_value': payload['user_override_value'],
      };
      final r = await http.post(
        Uri.parse('$_backendUrl/ai/log-override'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));
      if (r.statusCode != 200) return false;
      // Also update order status to OVERRIDDEN on backend if you have an endpoint
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _pushApproveOrder(Map<String, dynamic> payload) async {
    final orderId = payload['order_id'] as String?;
    final type = payload['order_type'] as String?;
    if (orderId == null || type == null) return false;
    try {
      final path = type.toLowerCase() == 'picking'
          ? '$_backendUrl/supervisor/picking-orders/$orderId/approve'
          : '$_backendUrl/supervisor/preparation-orders/$orderId/approve';
      final r = await http.post(
        Uri.parse(path),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _pushViaSupabase(String actionType, Map<String, dynamic> payload) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return false;
      dynamic response;
      switch (actionType) {
        case 'COMPLETE_STOP':
          response = await Supabase.instance.client.rpc('process_picking_stop', params: {
            'p_stop_id': payload['stop_id'],
            'p_qty_picked': payload['qty_picked'],
            'p_user_id': user.id,
          });
          break;
        case 'CONFIRM_RECEIPT':
          response = await Supabase.instance.client.rpc('process_receipt', params: {
            'p_order_id': payload['order_id'],
            'p_items': payload['received_items'],
            'p_user_id': user.id,
          });
          break;
        case 'TRANSFER_STOCK':
          response = await Supabase.instance.client.rpc('process_transfer', params: {
            'p_prod_id': payload['product_id'],
            'p_from_loc': payload['from_location_id'],
            'p_to_loc': payload['to_location_id'],
            'p_qty': payload['quantity'],
            'p_user_id': user.id,
          });
          break;
        case 'DELIVERY_VALIDATION':
          response = await Supabase.instance.client.rpc('process_delivery', params: {
            'p_order_id': payload['order_id'],
            'p_result': payload['result'],
            'p_notes': payload['notes'],
            'p_user_id': user.id,
          });
          break;
        default:
          return false;
      }
      final status = response is Map ? response['status'] : null;
      return status == 'SUCCESS' || status == 'CONFLICT';
    } catch (_) {
      return false;
    }
  }

  Future<void> _markActionSynced(int id) async {
    await (_db.update(_db.syncQueue)..where((tbl) => tbl.id.equals(id)))
        .write(SyncQueueCompanion(status: drift.Value('synced')));
  }

  Future<void> _pullLatestData() async {
    final userId = _getUserId();
    if (userId != null) {
      await _pullTasksFromBackend(userId);
      await _pullSupervisorPendingReviews();
    }
    await _pullFromSupabaseIfConfigured();
  }

  /// Keeps LocalPendingReviews updated so supervisor sees fresh AI reviews when opening the screen.
  Future<void> _pullSupervisorPendingReviews() async {
    try {
      final r = await http
          .get(Uri.parse('$_backendUrl/supervisor/pending-reviews'))
          .timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return;
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      final now = DateTime.now();
      for (final o in data['preparation_orders'] as List? ?? []) {
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
      for (final o in data['picking_orders'] as List? ?? []) {
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
    } catch (_) {}
  }

  Future<void> _pullTasksFromBackend(String userId) async {
    try {
      final r = await http
          .get(Uri.parse('$_backendUrl/employee/tasks/$userId'))
          .timeout(const Duration(seconds: 15));
      if (r.statusCode != 200) return;
      final list = jsonDecode(r.body) as List;
      for (final item in list) {
        final id = item['id']?.toString();
        if (id == null) continue;
        await _db.into(_db.localTasks).insertOnConflictUpdate(
          LocalTasksCompanion(
            id: drift.Value(id),
            type: drift.Value(item['order_type']?.toString() ?? 'general'),
            status: drift.Value(item['statut']?.toString() ?? 'pending'),
            data: drift.Value(jsonEncode(item)),
            createdAt: drift.Value(DateTime.now()),
            lastUpdated: drift.Value(DateTime.now()),
            syncStatus: const drift.Value('synced'),
          ),
        );
      }
    } catch (_) {
      // ignore
    }
  }

  Future<void> _pullFromSupabaseIfConfigured() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final response = await Supabase.instance.client.rpc('sync_pull', params: {
        'p_user_id': user.id,
        'p_last_sync': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      });
      final tasks = response['tasks'] as List?;
      if (tasks == null) return;
      for (final t in tasks) {
        final id = t['id']?.toString();
        if (id == null) continue;
        await _db.into(_db.localTasks).insertOnConflictUpdate(
          LocalTasksCompanion(
            id: drift.Value(id),
            type: drift.Value(t['type'] ?? 'general'),
            status: drift.Value(t['statut'] ?? 'pending'),
            data: drift.Value(jsonEncode(t)),
            createdAt: drift.Value(DateTime.now()),
            lastUpdated: drift.Value(DateTime.now()),
            syncStatus: const drift.Value('synced'),
          ),
        );
      }
    } catch (_) {
      // Supabase not required if using FastAPI only
    }
  }

  void subscribeToTasks() {
    try {
      Supabase.instance.client
          .from('tasks')
          .stream(primaryKey: ['id'])
          .listen((List<Map<String, dynamic>> data) {
        _handleRealtimeUpdate(data);
      });
    } catch (_) {
      // Realtime optional
    }
  }

  Future<void> _handleRealtimeUpdate(List<Map<String, dynamic>> tasks) async {
    for (final t in tasks) {
      final id = t['id']?.toString();
      if (id == null) continue;
      await _db.into(_db.localTasks).insertOnConflictUpdate(
        LocalTasksCompanion(
          id: drift.Value(id),
          type: drift.Value(t['type'] ?? 'general'),
          status: drift.Value(t['statut'] ?? 'pending'),
          data: drift.Value(jsonEncode(t)),
          createdAt: drift.Value(DateTime.now()),
          lastUpdated: drift.Value(DateTime.now()),
          syncStatus: const drift.Value('synced'),
        ),
      );
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _periodicSyncTimer?.cancel();
  }
}
