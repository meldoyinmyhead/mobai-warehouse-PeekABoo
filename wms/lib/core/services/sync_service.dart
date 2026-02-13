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
  
  // Singleton pattern
  static SyncService? _instance;
  
  SyncService._(this._supabase, this._db, this._connectivity);
  
  static Future<SyncService> init(AppDatabase db) async {
    if (_instance != null) return _instance!;
    
    final supabase = Supabase.instance.client;
    final connectivity = Connectivity();
    
    _instance = SyncService._(supabase, db, connectivity);
    
    // Listen to Auth Changes
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

  /// 1. Main Sync Loop
  /// Should be called periodically or when connection is restored.
  Future<void> runSync() async {
    // Check connection
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      print('[Sync] Offline. Skipping sync.');
      return;
    }

    try {
      print('[Sync] Starting Sync...');
      
      // A. Push Pending Actions
      await _pushPendingActions();
      
      // B. Pull New Data
      await _pullLatestData();
      
      print('[Sync] Sync Completed Successfully.');
    } catch (e) {
      print('[Sync] Error: $e');
    }
  }

  /// 2. PUSH: Send local actions to server
  Future<void> _pushPendingActions() async {
    // Get all pending actions from SyncQueue
    final pendingActions = await (_db.select(_db.syncQueue)
      ..where((tbl) => tbl.status.equals('pending')))
      .get();

    for (final action in pendingActions) {
      try {
        final payload = jsonDecode(action.payload);
        
        if (action.actionType == 'COMPLETE_STOP') {
             // Call Supabase RPC
             final response = await _supabase.rpc('process_picking_stop', params: {
               'p_stop_id': payload['stop_id'],
               'p_qty_picked': payload['qty_picked'],
               'p_user_id': _supabase.auth.currentUser!.id,
             });
             
             if (response['status'] == 'SUCCESS' || response['status'] == 'CONFLICT') {
                // If conflict, we mark as synced but maybe log error.
                // For now, treat conflict as "Handled by Server".
                await _markActionSynced(action.id);
             } else {
               // Retry logic?
             }
        }
        
      } catch (e) {
        print('[Sync] Error pushing action ${action.id}: $e');
        // Increment retry count?
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

  /// 3. PULL: Get updates from server
  Future<void> _pullLatestData() async {
    // Get last sync timestamp (mocked for now)
    final lastSync = DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
    
    final response = await _supabase.rpc('sync_pull', params: {
      'p_user_id': _supabase.auth.currentUser!.id,
      'p_last_sync': lastSync,
    });
    
    // Parse response
    final tasks = response['tasks'] as List;
    // Update local DB...
    print('[Sync] Pulled ${tasks.length} tasks updates.');
    
    // Example: Insert tasks into LocalTasks
    for (final t in tasks) {
      await _db.into(_db.localTasks).insertOnConflictUpdate(
        LocalTasksCompanion(
          id: drift.Value(t['id']),
          type: drift.Value('picking'), // Infer from table
          status: drift.Value(t['statut']),
          data: drift.Value(jsonEncode(t)),
          createdAt: drift.Value(DateTime.parse(t['created_at'])),
          lastUpdated: drift.Value(DateTime.now()),
          syncStatus: const drift.Value('synced'),
        )
      );
    }
  }
  /// 4. REALTIME: Listen for changes
  void subscribeToTasks() {
    print('[Realtime] Subscribing to tasks...');
    _supabase
        .from('tasks')
        .stream(primaryKey: ['id'])
        .listen((List<Map<String, dynamic>> data) {
          print('[Realtime] Received ${data.length} tasks update');
          _handleRealtimeUpdate(data);
        }, onError: (e) {
          print('[Realtime] Error: $e');
        });
  }

  Future<void> _handleRealtimeUpdate(List<Map<String, dynamic>> tasks) async {
    for (final t in tasks) {
      await _db.into(_db.localTasks).insertOnConflictUpdate(
        LocalTasksCompanion(
          id: drift.Value(t['id'].toString()), // Ensure string ID
          type: drift.Value('picking'),
          status: drift.Value(t['statut']),
          data: drift.Value(jsonEncode(t)),
          createdAt: drift.Value(DateTime.parse(t['created_at'])),
          lastUpdated: drift.Value(DateTime.now()),
          syncStatus: const drift.Value('synced'),
        )
      );
    }
    // Optionally notify UI via a StreamController or Cubit
  }
}
