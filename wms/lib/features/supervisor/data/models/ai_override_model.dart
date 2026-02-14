import 'package:equatable/equatable.dart';

enum AiOrderType { preparation, picking, storage }

class AiOverrideModel extends Equatable {
  final String id;
  final AiOrderType orderType;
  final String orderId;
  final String overriddenBy; // User ID
  final String justification;
  final Map<String, dynamic> aiSuggestion; // Snapshot of what AI suggested
  final Map<String, dynamic> finalDecision; // Snapshot of final decision
  final DateTime createdAt;

  const AiOverrideModel({
    required this.id,
    required this.orderType,
    required this.orderId,
    required this.overriddenBy,
    required this.justification,
    required this.aiSuggestion,
    required this.finalDecision,
    required this.createdAt,
  });

  factory AiOverrideModel.fromMap(Map<String, dynamic> map) {
    return AiOverrideModel(
      id: map['id'],
      orderType: AiOrderType.values.firstWhere(
        (e) => e.name.toUpperCase() == map['order_type'].toString().toUpperCase(),
        orElse: () => AiOrderType.preparation,
      ),
      orderId: map['order_id'],
      overriddenBy: map['overridden_by'],
      justification: map['justification'],
      aiSuggestion: map['ai_suggestion'] as Map<String, dynamic>,
      finalDecision: map['final_decision'] as Map<String, dynamic>,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id,
      'order_type': orderType.name.toUpperCase(),
      'order_id': orderId,
      'overridden_by': overriddenBy,
      'justification': justification,
      'ai_suggestion': aiSuggestion,
      'final_decision': finalDecision,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, orderType, orderId, overriddenBy, justification, aiSuggestion, finalDecision, createdAt];
}
