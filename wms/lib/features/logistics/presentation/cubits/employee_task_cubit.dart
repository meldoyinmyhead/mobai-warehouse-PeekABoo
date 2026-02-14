import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wms/features/logistics/data/models/task_model.dart';
import 'package:wms/features/logistics/data/repositories/task_repository.dart';

// States
abstract class EmployeeTaskState extends Equatable {
  const EmployeeTaskState();
  @override
  List<Object> get props => [];
}

class EmployeeTaskLoading extends EmployeeTaskState {}

class EmployeeTaskLoaded extends EmployeeTaskState {
  final List<TaskModel> tasks;
  final String filter; // 'All', 'Receipt', 'Storage', 'Picking', 'Delivery'

  const EmployeeTaskLoaded({required this.tasks, this.filter = 'All'});

  @override
  List<Object> get props => [tasks, filter];
}

class EmployeeTaskError extends EmployeeTaskState {
  final String message;
  const EmployeeTaskError(this.message);
  @override
  List<Object> get props => [message];
}

// Cubit
class EmployeeTaskCubit extends Cubit<EmployeeTaskState> {
  final TaskRepository _taskRepository;

  EmployeeTaskCubit(this._taskRepository) : super(EmployeeTaskLoading());

  // Helper to get filtered tasks for the UI
  List<TaskModel> get filteredTasks {
    if (state is EmployeeTaskLoaded) {
      final loadedState = state as EmployeeTaskLoaded;
      if (loadedState.filter == 'All') {
        return loadedState.tasks;
      }
      
      // Map filter string to TaskType
      TaskType? targetType;
      switch (loadedState.filter.toLowerCase()) {
        case 'reception':
        case 'receipt':
          targetType = TaskType.receipt;
          break;
        case 'stockage':
        case 'storage':
          targetType = TaskType.storage;
          break;
        case 'preparation':
        case 'picking':
          targetType = TaskType.picking;
          break;
        case 'delivery':
        case 'livraison':
          targetType = TaskType.delivery;
          break;
      }
      
      if (targetType != null) {
        return loadedState.tasks.where((t) => t.type == targetType).toList();
      }
      return loadedState.tasks;
    }
    return [];
  }

  Future<void> loadTasks(String employeeId) async {
    try {
      emit(EmployeeTaskLoading());
      final tasks = await _taskRepository.getEmployeeTasks(employeeId);
      emit(EmployeeTaskLoaded(tasks: tasks));
    } catch (e) {
      emit(EmployeeTaskError("Failed to load tasks: $e"));
    }
  }

  void refreshTasks(String employeeId) => loadTasks(employeeId);

  void filterTasks(String filter) {
    if (state is EmployeeTaskLoaded) {
      final currentState = state as EmployeeTaskLoaded;
      emit(EmployeeTaskLoaded(tasks: currentState.tasks, filter: filter));
    }
  }


  Future<void> completeTask(String taskId, String employeeId) async {
    try {
      final success = await _taskRepository.completeTask(taskId);
      if (success) {
        await loadTasks(employeeId); // Refresh list to remove completed task
      }
    } catch (e) {
      emit(EmployeeTaskError("Failed to complete task: $e"));
    }
  }
}
