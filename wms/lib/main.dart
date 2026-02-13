import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms/core/di/dependency_injection.dart';
import 'package:wms/core/routes/app_router.dart';
import 'package:wms/core/theme/app_theme.dart';
import 'package:wms/features/warehouse/data/repositories/task_repository.dart';
import 'package:wms/features/warehouse/presentation/cubits/employee/employee_task_cubit.dart';
import 'package:wms/features/warehouse/presentation/cubits/employee/employee_profile_cubit.dart';
import 'package:wms/features/warehouse/presentation/cubits/employee/employee_settings_cubit.dart';
import 'package:wms/features/warehouse/presentation/cubits/employee/employee_notification_cubit.dart';
import 'package:wms/features/warehouse/presentation/cubits/supervisor/map_cubit.dart';
import 'package:wms/features/warehouse/presentation/cubits/supervisor/ai_review_cubit.dart';
import 'package:wms/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:wms/features/auth/data/repositories/auth_repository.dart';


void main() {
  debugPrint("--- APP INITIALIZING ---");
  WidgetsFlutterBinding.ensureInitialized();
  setupDependencyInjection();
  debugPrint("--- DEPENDENCY INJECTION READY ---");
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<EmployeeTaskCubit>()..loadTasks()),
        BlocProvider(create: (_) => EmployeeProfileCubit()..loadProfile()),
        BlocProvider(create: (_) => EmployeeSettingsCubit()),
        BlocProvider(create: (_) => EmployeeNotificationCubit()),
        BlocProvider(create: (_) => MapCubit()),
        BlocProvider(create: (_) => AiReviewCubit()..loadPendingReviews()),
        BlocProvider(create: (_) => sl<AuthCubit>()),
      ],
      child: MaterialApp(
        title: 'WMS App',
        theme: AppTheme.lightTheme,
        initialRoute: AppRouter.landing,
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}
