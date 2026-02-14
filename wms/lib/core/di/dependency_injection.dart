import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:wms/core/database/app_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wms/core/repositories/offline_repository.dart';
import 'package:wms/core/services/sync_service.dart';
import 'package:wms/features/auth/data/repositories/auth_repository.dart';
import 'package:wms/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:wms/features/inventory/data/repositories/entrepot_repository.dart';
import 'package:wms/features/inventory/data/repositories/emplacement_repository.dart';
import 'package:wms/features/logistics/data/repositories/task_repository.dart';
import 'package:wms/features/supervisor/presentation/cubits/dashboard_cubit.dart';
import 'package:wms/features/logistics/presentation/cubits/employee_task_cubit.dart';
import 'package:wms/features/supervisor/presentation/cubits/ai_review_cubit.dart';
import 'package:wms/features/supervisor/presentation/cubits/flag_cubit.dart';
import 'package:wms/features/inventory/presentation/cubits/receipt_cubit.dart';
import 'package:wms/features/supervisor/data/repositories/ai_review_repository.dart';
import 'package:wms/features/supervisor/data/repositories/flag_repository.dart';
import 'package:wms/features/inventory/data/repositories/receipt_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wms/features/admin/data/repositories/admin_repository.dart';
import 'package:wms/features/admin/presentation/cubits/warehouse_cubit.dart';
import 'package:wms/features/admin/presentation/cubits/admin_user_cubit.dart';
import 'package:wms/core/app_config.dart';

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

  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPreferences);

  // Repositories
  sl.registerLazySingleton<EntrepotRepository>(() => EntrepotRepository());
  sl.registerLazySingleton<EmplacementRepository>(() => EmplacementRepository());
  sl.registerLazySingleton<TaskRepository>(() => TaskRepository(sl<AppDatabase>()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepository(sl<SharedPreferences>()));
  sl.registerLazySingleton<AiReviewRepository>(() => AiReviewRepository());
  sl.registerLazySingleton<FlagRepository>(() => FlagRepository());
  sl.registerLazySingleton<ReceiptRepository>(() => ReceiptRepository(Supabase.instance.client, sl()));
  sl.registerLazySingleton<AdminRepository>(() => AdminRepository(AppConfig.backendUrl));

  // Cubits
  sl.registerFactory<SupervisorDashboardCubit>(
    () => SupervisorDashboardCubit(sl<TaskRepository>()),
  );
  sl.registerFactory<EmployeeTaskCubit>(
    () => EmployeeTaskCubit(sl<TaskRepository>()), // Eventually switch to OfflineRepository
  );
  sl.registerLazySingleton<AuthCubit>(() => AuthCubit(sl<AuthRepository>()));
  sl.registerFactory<AiReviewCubit>(() => AiReviewCubit(sl<AiReviewRepository>()));
  sl.registerFactory<FlagCubit>(() => FlagCubit(sl<FlagRepository>()));
  sl.registerFactory<ReceiptCubit>(() => ReceiptCubit(sl<ReceiptRepository>()));
  sl.registerFactory<WarehouseCubit>(() => WarehouseCubit(sl<AdminRepository>()));
  sl.registerFactory<AdminUserCubit>(() => AdminUserCubit(sl<AdminRepository>()));
}
