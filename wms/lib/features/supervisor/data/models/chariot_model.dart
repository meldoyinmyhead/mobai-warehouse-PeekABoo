import 'package:equatable/equatable.dart';

enum ChariotStatus { available, inUse, maintenance }

class ChariotModel extends Equatable {
  final String id;
  final String codeChariot;
  final ChariotStatus statut;
  final String idEntrepot;
  final String? lastKnownLocation;
  final bool actif;

  const ChariotModel({
    required this.id,
    required this.codeChariot,
    required this.statut,
    required this.idEntrepot,
    this.lastKnownLocation,
    this.actif = true,
  });

  factory ChariotModel.fromJson(Map<String, dynamic> json) {
    return ChariotModel(
      id: json['id'] as String,
      codeChariot: json['code_chariot'] as String,
      statut: _parseStatus(json['statut'] as String),
      idEntrepot: json['id_entrepot'] as String,
      lastKnownLocation: json['last_known_location'] as String?,
      actif: json['actif'] as bool? ?? true,
    );
  }

  static ChariotStatus _parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'AVAILABLE':
        return ChariotStatus.available;
      case 'IN_USE':
        return ChariotStatus.inUse;
      case 'MAINTENANCE':
        return ChariotStatus.maintenance;
      default:
        return ChariotStatus.available;
    }
  }

  String get printableStatus {
    switch (statut) {
      case ChariotStatus.available:
        return 'Standby';
      case ChariotStatus.inUse:
        return 'En service';
      case ChariotStatus.maintenance:
        return 'Maintenance';
    }
  }

  @override
  List<Object?> get props => [id, codeChariot, statut, idEntrepot, lastKnownLocation, actif];
}
