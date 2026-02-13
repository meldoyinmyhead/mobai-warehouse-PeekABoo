import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wms/features/auth/data/user_model.dart';

class AuthRepository {
  final String baseUrl = 'http://127.0.0.1:8000'; // Keep for other endpoints if needed
  
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Return a map similar to what the app expects, or adapt the Cubit
        return {
          'token': response.session?.accessToken,
          'user_id': response.user?.id,
          'email': response.user?.email,
          'role': response.user?.userMetadata?['role'] ?? 'employee', // Assuming metadata
        };
      } else {
        throw Exception('Login failed: No user returned');
      }
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
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
