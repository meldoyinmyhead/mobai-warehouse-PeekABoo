import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:wms/core/database/app_database.dart';
import 'package:wms/features/auth/data/repositories/auth_repository.dart';
import 'package:wms/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:wms/features/warehouse/data/repositories/entrepot_repository.dart';
import 'package:wms/features/warehouse/data/repositories/emplacement_repository.dart';
import 'package:wms/features/warehouse/data/repositories/task_repository.dart';
import 'package:wms/features/warehouse/presentation/cubits/supervisor/dashboard_cubit.dart';
import 'package:wms/features/warehouse/presentation/cubits/employee/employee_task_cubit.dart';

final sl = GetIt.instance;

void setupDependencyInjection() {
  debugPrint("Setting up dependency injection...");
  // Database
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase());

  // Repositories
  sl.registerLazySingleton<EntrepotRepository>(() => EntrepotRepository());
  sl.registerLazySingleton<EmplacementRepository>(() => EmplacementRepository());
  sl.registerLazySingleton<TaskRepository>(() => TaskRepository());
  sl.registerLazySingleton<AuthRepository>(() => AuthRepository());

  // Cubits
  sl.registerFactory<SupervisorDashboardCubit>(
    () => SupervisorDashboardCubit(sl<TaskRepository>()),
  );
  sl.registerFactory<EmployeeTaskCubit>(
    () => EmployeeTaskCubit(sl<TaskRepository>()),
  );
  sl.registerLazySingleton<AuthCubit>(() => AuthCubit(sl<AuthRepository>()));
}
