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

  @override
  List<Object?> get props => [id, orderType, orderId, overriddenBy, justification, aiSuggestion, finalDecision, createdAt];
}
