import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wms/features/logistics/data/models/task_model.dart';
import 'package:wms/features/supervisor/data/repositories/ai_review_repository.dart';
import 'package:wms/features/supervisor/data/repositories/flag_repository.dart';
import 'package:wms/features/supervisor/data/models/flag_model.dart';

// States
abstract class SupervisorDashboardState extends Equatable {
  const SupervisorDashboardState();
  @override
  List<Object> get props => [];
}

class SupervisorDashboardLoading extends SupervisorDashboardState {}

class SupervisorDashboardLoaded extends SupervisorDashboardState {
  final List<TaskModel> pendingValidations;
  final List<TaskModel> flaggedTasks;
  final List<Map<String, dynamic>> employees;
  final List<Map<String, dynamic>> chariots;
  final int flaggedCount;
  final int aiPendingCount;

  const SupervisorDashboardLoaded({
    required this.pendingValidations,
    required this.flaggedTasks,
    required this.employees,
    required this.chariots,
    this.flaggedCount = 0,
    this.aiPendingCount = 0,
  });

  @override
  List<Object> get props => [
        pendingValidations,
        flaggedTasks,
        employees,
        chariots,
        flaggedCount,
        aiPendingCount
      ];
}

class SupervisorDashboardError extends SupervisorDashboardState {
  final String message;
  const SupervisorDashboardError(this.message);
  @override
  List<Object> get props => [message];
}

// Cubit: real data from AiReviewRepository and FlagRepository.
class SupervisorDashboardCubit extends Cubit<SupervisorDashboardState> {
  final AiReviewRepository _aiReviewRepository;
  final FlagRepository _flagRepository;

  SupervisorDashboardCubit(this._aiReviewRepository, this._flagRepository) : super(SupervisorDashboardLoading());

  Future<void> loadDashboard() async {
    try {
      emit(SupervisorDashboardLoading());

      final pendingReviews = await _aiReviewRepository.getPendingAiOrders();
      final employees = await _aiReviewRepository.getEmployees();
      final chariots = await _aiReviewRepository.getChariots();
      
      List<FlagModel> flags = [];
      try {
        flags = await _flagRepository.getAllFlags();
      } catch (_) {}

      emit(SupervisorDashboardLoaded(
        pendingValidations: [],
        flaggedTasks: [],
        employees: employees,
        chariots: chariots,
        flaggedCount: flags.length,
        aiPendingCount: pendingReviews.length,
      ));
    } catch (e) {
      emit(SupervisorDashboardError("Échec du chargement: $e"));
    }
  }
}
