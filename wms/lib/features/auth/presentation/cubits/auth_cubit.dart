import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wms/features/auth/data/user_model.dart';
import 'package:wms/features/auth/data/repositories/auth_repository.dart';

// --- States ---
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final UserModel user;
  final String token;
  const Authenticated({required this.user, required this.token});

  @override
  List<Object?> get props => [user, token];
}

class Unauthenticated extends AuthState {
  final String? message;
  const Unauthenticated({this.message});

  @override
  List<Object?> get props => [message];
}

// --- Cubit ---
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit(this._authRepository) : super(AuthInitial());

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      final response = await _authRepository.login(email, password);
      final user = UserModel.fromJson(response['user']);
      final token = response['access_token'];
      
      emit(Authenticated(user: user, token: token));
    } catch (e) {
      emit(Unauthenticated(message: e.toString()));
    }
  }

  Future<void> checkSession() async {
    try {
      final session = await _authRepository.checkSession();
      if (session != null) {
        final user = UserModel.fromJson(session['user']);
        final token = session['access_token'];
        emit(Authenticated(user: user, token: token));
      } else {
        emit(const Unauthenticated());
      }
    } catch (e) {
      emit(const Unauthenticated());
    }
  }

  void logout() {
    _authRepository.logout();
    emit(const Unauthenticated());
  }

  Future<void> logUserAction({
    required String action,
    required String entityType,
    required String entityId,
    Map<String, dynamic>? payload,
  }) async {
    if (state is Authenticated) {
      final user = (state as Authenticated).user;
      await _authRepository.logAction(
        userId: user.id,
        action: action,
        entityType: entityType,
        entityId: entityId,
        payload: payload,
      );
    }
  }
}
