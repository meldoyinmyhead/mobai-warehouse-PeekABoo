import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:wms/features/auth/data/user_model.dart';

class AuthRepository {
  final String baseUrl = 'http://127.0.0.1:8000'; // Adjust for physical device if needed

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to login');
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
