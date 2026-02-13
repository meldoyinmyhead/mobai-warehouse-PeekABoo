import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wms/features/warehouse/data/models/ai_override_model.dart';

abstract class AiReviewState extends Equatable {
  const AiReviewState();
  @override
  List<Object?> get props => [];
}

class AiReviewInitial extends AiReviewState {}

class AiReviewLoading extends AiReviewState {}

class AiReviewLoaded extends AiReviewState {
  final List<Map<String, dynamic>> pendingOrders; // Mocked order data
  final List<AiOverrideModel> overrides;

  const AiReviewLoaded({required this.pendingOrders, this.overrides = const []});

  @override
  List<Object?> get props => [pendingOrders, overrides];
}

class AiReviewError extends AiReviewState {
  final String message;
  const AiReviewError(this.message);

  @override
  List<Object?> get props => [message];
}

class AiReviewCubit extends Cubit<AiReviewState> {
  AiReviewCubit() : super(AiReviewInitial());

  void loadPendingReviews() async {
    emit(AiReviewLoading());
    // Mocking AI generated orders
    await Future.delayed(const Duration(seconds: 1));
    final mockOrders = [
      {
        'id': 'PREP-2026-042',
        'type': AiOrderType.preparation,
        'product': 'Samsung Mobile Phones',
        'ai_quantity': 50,
        'current_stock': 12,
        'status': 'DRAFT',
      },
      {
        'id': 'PICK-2026-007',
        'type': AiOrderType.picking,
        'product': 'Computer Parts',
        'ai_route': ['B7-N1-C2', 'B7-N2-C4', 'B7-0A-01-01'],
        'status': 'DRAFT',
      },
    ];
    emit(AiReviewLoaded(pendingOrders: mockOrders));
  }

  void approveOrder(String orderId) {
    if (state is AiReviewLoaded) {
      final current = state as AiReviewLoaded;
      final updated = current.pendingOrders.where((o) => o['id'] != orderId).toList();
      emit(AiReviewLoaded(pendingOrders: updated, overrides: current.overrides));
      // In a real app, this would trigger an update to TransactionRepository
    }
  }

  void overrideOrder({
    required String orderId,
    required String justification,
    required Map<String, dynamic> finalDecision,
  }) {
    if (state is AiReviewLoaded) {
      final current = state as AiReviewLoaded;
      final order = current.pendingOrders.firstWhere((o) => o['id'] == orderId);

      final newOverride = AiOverrideModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        orderType: order['type'],
        orderId: orderId,
        overriddenBy: 'SUPERVISOR-001', // Mock user
        justification: justification,
        aiSuggestion: order,
        finalDecision: finalDecision,
        createdAt: DateTime.now(),
      );

      final updatedOrders = current.pendingOrders.where((o) => o['id'] != orderId).toList();
      emit(AiReviewLoaded(
        pendingOrders: updatedOrders,
        overrides: [...current.overrides, newOverride],
      ));
    }
  }
}
