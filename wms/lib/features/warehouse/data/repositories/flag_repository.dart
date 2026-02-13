import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wms/core/data/repositories/base_repository_impl.dart';
import 'package:wms/features/warehouse/data/models/flag_model.dart';

class FlagRepository extends BaseRepositoryImpl<FlagModel> {
  final SupabaseClient _supabase = Supabase.instance.client;

  FlagRepository() : super('signalements');

  @override
  FlagModel fromMap(Map<String, dynamic> map) {
    return FlagModel.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap(FlagModel item) {
    return item.toMap();
  }

  /// Fetch all flags with joined location codes and reporter names for the supervisor
  Future<List<FlagModel>> getAllFlags() async {
    final response = await _supabase
        .from('signalements')
        .select('''
          *,
          emplacements!id_emplacement (
            code_emplacement,
            entrepots (code_entrepot)
          ),
          utilisateurs!id_utilisateur_rapporteur (nom_complet)
        ''')
        .order('created_at', ascending: false);

    return (response as List).map((data) {
      // Flatten joined data for the model
      final map = Map<String, dynamic>.from(data);
      map['location_code'] = data['emplacements']?['code_emplacement'];
      map['reporter_name'] = data['utilisateurs']?['nom_complet'];
      map['warehouse_code'] = data['emplacements']?['entrepots']?['code_entrepot'];
      return FlagModel.fromMap(map);
    }).toList();
  }

  Future<void> updateFlagStatus(String id, FlagStatus status) async {
    await _supabase
        .from('signalements')
        .update({'statut': status.name})
        .eq('id', id);
  }
}
