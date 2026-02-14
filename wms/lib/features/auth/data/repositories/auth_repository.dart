import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wms/features/auth/data/user_model.dart';

import 'package:wms/core/app_config.dart';

import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  final SharedPreferences _prefs;
  final String baseUrl = AppConfig.backendUrl;
  
  AuthRepository(this._prefs);

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
      } else if (response.statusCode == 401) {
        throw Exception('Email ou mot de passe incorrect.');
      } else if (response.statusCode == 403) {
        throw Exception('Compte désactivé contactez l\'administrateur.');
      } else {
        throw Exception('Erreur de connexion: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) rethrow; 
      throw Exception('Erreur technique: ${e.toString()}');
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

  Future<void> logAction({
    required String userId,
    required String action,
    required String entityType,
    required String entityId,
    Map<String, dynamic>? payload,
  }) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/audit/log'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_utilisateur': userId,
          'action': action,
          'entity_type': entityType,
          'entity_id': entityId,
          'payload': payload,
        }),
      );
    } catch (e) {
      print('Audit logging failed: $e');
    }
  }
}
