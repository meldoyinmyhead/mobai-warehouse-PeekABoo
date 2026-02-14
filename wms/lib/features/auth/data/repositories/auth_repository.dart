import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wms/features/auth/data/user_model.dart';

import 'package:wms/core/app_config.dart';

class AuthRepository {
  final String baseUrl = AppConfig.backendUrl;
  
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
      // In a production app, queue for retry
    }
  }
}
