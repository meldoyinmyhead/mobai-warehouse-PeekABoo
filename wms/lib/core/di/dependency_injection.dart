import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:wms/core/database/app_database.dart';
import 'package:wms/core/repositories/offline_repository.dart';
import 'package:wms/core/services/sync_service.dart';
import 'package:wms/features/auth/data/repositories/auth_repository.dart';
import 'package:wms/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:wms/features/warehouse/data/repositories/entrepot_repository.dart';
import 'package:wms/features/warehouse/data/repositories/emplacement_repository.dart';
import 'package:wms/features/warehouse/data/repositories/task_repository.dart';
import 'package:wms/features/warehouse/presentation/cubits/supervisor/dashboard_cubit.dart';
import 'package:wms/features/warehouse/presentation/cubits/employee/employee_task_cubit.dart';
import 'package:wms/features/warehouse/presentation/cubits/supervisor/ai_review_cubit.dart'; // Added missing import

final sl = GetIt.instance;

Future<void> setupDependencyInjection() async {
  debugPrint("Setting up dependency injection...");
  
  // Database & Core Services
  final db = AppDatabase();
  sl.registerSingleton<AppDatabase>(db);
  
  sl.registerLazySingleton<OfflineRepository>(() => OfflineRepository(sl()));
  
  // Sync Service needs async init
  final syncService = await SyncService.init(sl());
  sl.registerSingleton<SyncService>(syncService);

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
    () => EmployeeTaskCubit(sl<TaskRepository>()), // Eventually switch to OfflineRepository
  );
  sl.registerLazySingleton<AuthCubit>(() => AuthCubit(sl<AuthRepository>()));
}
