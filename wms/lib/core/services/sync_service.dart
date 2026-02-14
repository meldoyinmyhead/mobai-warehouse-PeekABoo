import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wms/core/database/app_database.dart';
import 'package:drift/drift.dart' as drift;

class SyncService {
  final SupabaseClient _supabase;
  final AppDatabase _db;
  final Connectivity _connectivity;
  
  static SyncService? _instance;
  
  SyncService._(this._supabase, this._db, this._connectivity);
  
  static Future<SyncService> init(AppDatabase db) async {
    if (_instance != null) return _instance!;
    
    final supabase = Supabase.instance.client;
    final connectivity = Connectivity();
    
    _instance = SyncService._(supabase, db, connectivity);
    
    supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        print('[Sync] User signed in. Starting Realtime & Sync.');
        _instance!.subscribeToTasks();
        _instance!.runSync();
      }
    });
    
    return _instance!;
  }

  Future<void> runSync() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      print('[Sync] Offline. Skipping sync.');
      return;
    }

    try {
      print('[Sync] Starting Sync...');
      await _pushPendingActions();
      await _pullLatestData();
      print('[Sync] Sync Completed Successfully.');
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
        final payload = jsonDecode(action.payload);
        Map<String, dynamic>? response;

        switch (action.actionType) {
          case 'COMPLETE_TASK':
            response = await _supabase.rpc('process_task_completion', params: {
              'p_task_id': payload['task_id'],
              'p_user_id': _supabase.auth.currentUser!.id,
            });
            break;
            
          case 'COMPLETE_STOP':
            response = await _supabase.rpc('process_picking_stop', params: {
              'p_stop_id': payload['stop_id'],
              'p_qty_picked': payload['qty_picked'],
              'p_user_id': _supabase.auth.currentUser!.id,
            });
            break;
            
          case 'CONFIRM_RECEIPT':
            response = await _supabase.rpc('process_receipt', params: {
              'p_order_id': payload['order_id'],
              'p_items': payload['received_items'],
              'p_user_id': _supabase.auth.currentUser!.id,
            });
            break;

          case 'TRANSFER_STOCK':
            response = await _supabase.rpc('process_transfer', params: {
               'p_prod_id': payload['product_id'],
               'p_from_loc': payload['from_location_id'],
               'p_to_loc': payload['to_location_id'],
               'p_qty': payload['quantity'],
               'p_user_id': _supabase.auth.currentUser!.id,
            });
            break;

           case 'DELIVERY_VALIDATION':
            response = await _supabase.rpc('process_delivery', params: {
               'p_order_id': payload['order_id'],
               'p_result': payload['result'],
               'p_notes': payload['notes'],
               'p_user_id': _supabase.auth.currentUser!.id,
            });
            break;
        }

        if (response != null && (response['status'] == 'SUCCESS' || response['status'] == 'CONFLICT')) {
          await _markActionSynced(action.id);
        }
        
      } catch (e) {
        print('[Sync] Error pushing action ${action.id}: $e');
      }
    }
  }

  Future<void> _markActionSynced(int id) async {
    await (_db.update(_db.syncQueue)
      ..where((tbl) => tbl.id.equals(id)))
      .write(SyncQueueCompanion(
        status: drift.Value('synced'),
      ));
  }

  Future<void> _pullLatestData() async {
    final lastSync = DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
    
    final response = await _supabase.rpc('sync_pull', params: {
      'p_user_id': _supabase.auth.currentUser!.id,
      'p_last_sync': lastSync,
    });
    
    final tasks = response['tasks'] as List;
    
    for (final t in tasks) {
      await _db.into(_db.localTasks).insertOnConflictUpdate(
        LocalTasksCompanion(
          id: drift.Value(t['id'].toString()),
          type: drift.Value(t['type'] ?? 'general'),
          status: drift.Value(t['statut']),
          data: drift.Value(jsonEncode(t)),
          createdAt: drift.Value(DateTime.parse(t['created_at'])),
          lastUpdated: drift.Value(DateTime.now()),
          syncStatus: const drift.Value('synced'),
        )
      );
    }
  }

  void subscribeToTasks() {
    _supabase
        .from('tasks')
        .stream(primaryKey: ['id'])
        .listen((List<Map<String, dynamic>> data) {
          _handleRealtimeUpdate(data);
        });
  }

  Future<void> _handleRealtimeUpdate(List<Map<String, dynamic>> tasks) async {
    for (final t in tasks) {
      await _db.into(_db.localTasks).insertOnConflictUpdate(
        LocalTasksCompanion(
          id: drift.Value(t['id'].toString()),
          type: drift.Value(t['type'] ?? 'general'),
          status: drift.Value(t['statut']),
          data: drift.Value(jsonEncode(t)),
          createdAt: drift.Value(DateTime.parse(t['created_at'])),
          lastUpdated: drift.Value(DateTime.now()),
          syncStatus: const drift.Value('synced'),
        )
      );
    }
  }
}
