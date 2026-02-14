import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms/features/auth/data/user_model.dart';
import 'package:wms/features/admin/data/repositories/admin_repository.dart';

abstract class AdminUserState {}

class AdminUserInitial extends AdminUserState {}

class AdminUserLoading extends AdminUserState {}

class AdminUserLoaded extends AdminUserState {
  final List<UserModel> users;
  AdminUserLoaded(this.users);
}

class AdminUserError extends AdminUserState {
  final String message;
  AdminUserError(this.message);
}

class AdminUserCubit extends Cubit<AdminUserState> {
  final AdminRepository repository;

  AdminUserCubit(this.repository) : super(AdminUserInitial());

  Future<void> loadUsers() async {
    emit(AdminUserLoading());
    try {
      final users = await repository.getUsers();
      emit(AdminUserLoaded(users));
    } catch (e) {
      emit(AdminUserError(e.toString()));
    }
  }

  Future<void> createUser(UserModel user, String password) async {
    try {
      await repository.createUser(user, password);
      loadUsers();
    } catch (e) {
      emit(AdminUserError(e.toString()));
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await repository.updateUser(user.id, user);
      loadUsers();
    } catch (e) {
      emit(AdminUserError(e.toString()));
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await repository.deleteUser(userId);
      loadUsers();
    } catch (e) {
      emit(AdminUserError(e.toString()));
    }
  }
}
