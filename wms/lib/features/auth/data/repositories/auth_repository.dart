import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wms/features/auth/data/user_model.dart';

import 'package:wms/core/app_config.dart';

class AuthRepository {
  final String baseUrl = AppConfig.backendUrl;
  
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        try {
          // Fetch user profile from public.utilisateurs to get role and name
          final userProfile = await Supabase.instance.client
              .from('utilisateurs')
              .select()
              .eq('id_utilisateur', response.user!.id)
              .single();

          return {
            'user': userProfile, 
            'access_token': response.session?.accessToken,
          };
        } on PostgrestException catch (e) {
          if (e.code == 'PGRST116') {
            throw Exception('Profil introuvable dans la base de données. Veuillez contacter l\'administrateur.');
          }
          rethrow;
        }
      } else {
        throw Exception('Login failed: No user returned');
      }
    } catch (e) {
      if (e is Exception) rethrow;
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
