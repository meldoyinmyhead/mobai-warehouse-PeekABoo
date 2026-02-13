import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// Models
class NotificationModel extends Equatable {
  final String id;
  final String title;
  final String message;
  final String time;
  final bool isRead;
  final String type; // 'success', 'info', 'warning'

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    this.isRead = false,
    required this.type,
  });

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      time: time,
      isRead: isRead ?? this.isRead,
      type: type,
    );
  }

  @override
  List<Object> get props => [id, title, message, time, isRead, type];
}

// States
abstract class EmployeeNotificationState extends Equatable {
  const EmployeeNotificationState();
  @override
  List<Object> get props => [];
}

class EmployeeNotificationLoading extends EmployeeNotificationState {}

class EmployeeNotificationLoaded extends EmployeeNotificationState {
  final List<NotificationModel> notifications;

  const EmployeeNotificationLoaded(this.notifications);

  @override
  List<Object> get props => [notifications];
}

// Cubit
class EmployeeNotificationCubit extends Cubit<EmployeeNotificationState> {
  EmployeeNotificationCubit() : super(EmployeeNotificationLoading());

  Future<void> loadNotifications() async {
    emit(EmployeeNotificationLoading());
    // Mock data based on screenshot
    final mockNotifications = [
      const NotificationModel(
        id: '1',
        title: 'Task Completed',
        message: 'You have successfully completed the receipt task RCP-2026-001',
        time: '5 min ago',
        type: 'success',
      ),
      const NotificationModel(
        id: '2',
        title: 'New Task Assigned',
        message: 'A new delivery task has been assigned to you',
        time: '1 hour ago',
        type: 'info',
      ),
      const NotificationModel(
        id: '3',
        title: 'Issue Reported',
        message: 'An issue was reported for storage location B7-N2-C5',
        time: '2 hours ago',
        type: 'warning',
      ),
    ];
    emit(EmployeeNotificationLoaded(mockNotifications));
  }

  void markAsRead(String id) {
    if (state is EmployeeNotificationLoaded) {
      final currentState = state as EmployeeNotificationLoaded;
      final updatedList = currentState.notifications.map((n) {
        if (n.id == id) return n.copyWith(isRead: true);
        return n;
      }).toList();
      emit(EmployeeNotificationLoaded(updatedList));
    }
  }
}
