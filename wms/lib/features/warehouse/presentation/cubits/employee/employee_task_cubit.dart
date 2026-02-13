import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wms/features/warehouse/data/models/task_model.dart';
import 'package:wms/features/warehouse/data/repositories/task_repository.dart';

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

  Future<void> loadTasks() async {
    try {
      emit(EmployeeTaskLoading());
      // In a real app, you would filter by assigned user ID.
      // For now, fetching all tasks as a placeholder.
      final tasks = await _taskRepository.getAll();
      emit(EmployeeTaskLoaded(tasks: tasks));
    } catch (e) {
      emit(EmployeeTaskError("Failed to load tasks: $e"));
    }
  }

  void filterTasks(String filter) {
    if (state is EmployeeTaskLoaded) {
      final currentState = state as EmployeeTaskLoaded;
      emit(EmployeeTaskLoaded(tasks: currentState.tasks, filter: filter));
    }
  }
}
