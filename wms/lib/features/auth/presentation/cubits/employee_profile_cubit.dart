import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// States
abstract class EmployeeProfileState extends Equatable {
  const EmployeeProfileState();
  @override
  List<Object> get props => [];
}

class EmployeeProfileLoading extends EmployeeProfileState {}

class EmployeeProfileLoaded extends EmployeeProfileState {
  final String name;
  final String role;
  final String employeeId;
  final String email;
  final String phone;

  const EmployeeProfileLoaded({
    required this.name,
    required this.role,
    required this.employeeId,
    required this.email,
    required this.phone,
  });

  @override
  List<Object> get props => [name, role, employeeId, email, phone];
}

class EmployeeProfileError extends EmployeeProfileState {
  final String message;
  const EmployeeProfileError(this.message);
  @override
  List<Object> get props => [message];
}

// Cubit
class EmployeeProfileCubit extends Cubit<EmployeeProfileState> {
  EmployeeProfileCubit() : super(EmployeeProfileLoading());

  Future<void> loadProfile() async {
    try {
      emit(EmployeeProfileLoading());
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      emit(const EmployeeProfileLoaded(
        name: 'Mobina Sadat',
        role: 'Warehouse Operator',
        employeeId: 'EMP-2026-001',
        email: 'mobina.sadat@bms.com',
        phone: '+971 50 123 4567',
      ));
    } catch (e) {
      emit(EmployeeProfileError("Failed to load profile: $e"));
    }
  }

  Future<void> updateProfile({String? email, String? phone}) async {
     if (state is EmployeeProfileLoaded) {
       final currentState = state as EmployeeProfileLoaded;
       emit(EmployeeProfileLoading());
       // Simulate API call
       await Future.delayed(const Duration(seconds: 1));
       emit(EmployeeProfileLoaded(
         name: currentState.name,
         role: currentState.role,
         employeeId: currentState.employeeId,
         email: email ?? currentState.email,
         phone: phone ?? currentState.phone,
       ));
     }
  }
}
