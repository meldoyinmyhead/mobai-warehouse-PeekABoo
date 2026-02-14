import 'package:equatable/equatable.dart';

enum FlagType { DAMAGED, QUANTITY, LOCATION, OTHER }
enum FlagPriority { HIGH, MEDIUM, LOW }
enum FlagStatus { PENDING, IN_PROGRESS, RESOLVED }

class FlagModel extends Equatable {
  final String id;
  final FlagType type;
  final FlagPriority priority;
  final String description;
  final String? locationId;
  final String? locationCode; // For display
  final String reporterId;
  final String? reporterName; // For display
  final String? warehouseCode; // For display
  final FlagStatus status;
  final String? taskRef;
  final DateTime createdAt;

  const FlagModel({
    required this.id,
    required this.type,
    required this.priority,
    required this.description,
    this.locationId,
    this.locationCode,
    required this.reporterId,
    this.reporterName,
    this.warehouseCode,
    required this.status,
    this.taskRef,
    required this.createdAt,
  });

  factory FlagModel.fromMap(Map<String, dynamic> map) {
    return FlagModel(
      id: map['id'],
      type: _parseType(map['type_signalement']),
      priority: _parsePriority(map['priorite']),
      description: map['description'],
      locationId: map['id_emplacement'],
      locationCode: map['location_code'], // Joined field
      reporterId: map['id_utilisateur_rapporteur'],
      reporterName: map['reporter_name'], // Joined field
      warehouseCode: map['warehouse_code'], // Joined field
      status: _parseStatus(map['statut']),
      taskRef: map['reference_tache'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id,
      'type_signalement': type.name,
      'priorite': priority.name,
      'description': description,
      'id_emplacement': locationId,
      'id_utilisateur_rapporteur': reporterId,
      'statut': status.name,
      'reference_tache': taskRef,
    };
  }

  static FlagType _parseType(String? val) {
    return FlagType.values.firstWhere(
      (e) => e.name == val,
      orElse: () => FlagType.OTHER,
    );
  }

  static FlagPriority _parsePriority(String? val) {
    return FlagPriority.values.firstWhere(
      (e) => e.name == val,
      orElse: () => FlagPriority.MEDIUM,
    );
  }

  static FlagStatus _parseStatus(String? val) {
    if (val == 'En Attente') return FlagStatus.PENDING;
    if (val == 'En Cours') return FlagStatus.IN_PROGRESS;
    if (val == 'Résolu') return FlagStatus.RESOLVED;
    
    return FlagStatus.values.firstWhere(
      (e) => e.name == val,
      orElse: () => FlagStatus.PENDING,
    );
  }

  @override
  List<Object?> get props => [id, type, priority, description, locationId, reporterId, status, taskRef, createdAt, warehouseCode];
}
