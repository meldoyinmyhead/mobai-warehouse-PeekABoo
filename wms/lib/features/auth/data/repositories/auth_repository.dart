import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wms/features/auth/data/user_model.dart';

import 'package:wms/core/app_config.dart';

import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  final SharedPreferences _prefs;
  final AppDatabase? _db; // Optional for offline queuing
  final String baseUrl = AppConfig.backendUrl;
  
  AuthRepository(this._prefs, [this._db]);

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Persist Session
        await _prefs.setString('access_token', data['access_token']);
        await _prefs.setString('user_data', jsonEncode(data['user']));
        
        return {
          'user': data['user'],
          'access_token': data['access_token'],
        };
      }
      String? detail;
      try {
        final body = jsonDecode(response.body);
        if (body is Map && body['detail'] != null) {
          detail = body['detail'] is String ? body['detail'] as String : body['detail'].toString();
        }
      } catch (_) {}
      if (response.statusCode == 401) {
        throw Exception(detail ?? 'Incorrect email or password.');
      }
      if (response.statusCode == 403) {
        throw Exception(detail ?? 'Your account has been disabled. Please contact your administrator.');
      }
      throw Exception(detail ?? 'Connection error. Please try again later.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Connection error. Please check your internet and try again.');
    }
  }

  /// Current user id from stored session (for sync / offline queue). Returns null if not logged in.
  String? getCurrentUserId() {
    final userStr = _prefs.getString('user_data');
    if (userStr == null) return null;
    try {
      final m = jsonDecode(userStr) as Map<String, dynamic>;
      return m['id_utilisateur']?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> checkSession() async {
    final token = _prefs.getString('access_token');
    final userStr = _prefs.getString('user_data');
    
    if (token != null && userStr != null) {
      return {
        'access_token': token,
        'user': jsonDecode(userStr)
      };
    }
    return null;
  }
  
  Future<void> logout() async {
    await _prefs.remove('access_token');
    await _prefs.remove('user_data');
  }

  /// Logs action to backend audit_log. Returns true if sent successfully (2xx) or queued offline.
  Future<bool> logAction({
    required String userId,
    required String action,
    required String entityType,
    required String entityId,
    Map<String, dynamic>? payload,
  }) async {
    final body = {
      'id_utilisateur': userId,
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'payload': payload,
    };

    try {
      final r = await http.post(
        Uri.parse('$baseUrl/audit/log'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 5));

      if (r.statusCode >= 200 && r.statusCode < 300) {
        return true;
      }
      throw Exception('Server error: ${r.statusCode}');
    } catch (e) {
      print('Audit logging failed, queuing offline: $e');
      
      if (_db != null) {
        try {
          await _db!.into(_db!.syncQueue).insert(
            SyncQueueCompanion.insert(
              actionType: 'AUDIT_LOG',
              payload: jsonEncode(body),
              timestamp: DateTime.now(),
              status: const Value('pending'),
            ),
          );
          return true; // Successfully queued
        } catch (dbError) {
          print('Failed to queue audit log: $dbError');
        }
      }
      return false;
    }
  }
}
