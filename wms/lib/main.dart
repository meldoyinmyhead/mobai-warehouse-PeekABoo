import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms/core/di/dependency_injection.dart';
import 'package:wms/core/routes/app_router.dart';
import 'package:wms/core/theme/app_theme.dart';
import 'package:wms/features/logistics/presentation/cubits/employee_task_cubit.dart';
import 'package:wms/features/auth/presentation/cubits/employee_profile_cubit.dart';
import 'package:wms/features/auth/presentation/cubits/employee_settings_cubit.dart';
import 'package:wms/features/auth/presentation/cubits/employee_notification_cubit.dart';
import 'package:wms/features/supervisor/presentation/cubits/map_cubit.dart';
import 'package:wms/features/supervisor/presentation/cubits/ai_review_cubit.dart';
import 'package:wms/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:wms/features/auth/data/repositories/auth_repository.dart';
import 'package:wms/features/inventory/presentation/cubits/receipt_cubit.dart'; // Added missing receipt cubit
import 'package:wms/features/admin/presentation/pages/admin_dashboard_screen.dart'; // Assuming admin feature exists
import 'package:wms/features/inventory/presentation/pages/employee_main_screen.dart';
import 'package:wms/features/supervisor/presentation/pages/supervisor_dashboard_screen.dart';


import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wms/core/app_config.dart';
import 'package:wms/features/supervisor/data/repositories/ai_review_repository.dart';

void main() async {
  debugPrint("--- APP INITIALIZING ---");
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );
  
  await setupDependencyInjection();
  debugPrint("--- DEPENDENCY INJECTION READY ---");
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<EmployeeTaskCubit>()),
        BlocProvider(create: (_) => EmployeeProfileCubit()..loadProfile()),
        BlocProvider(create: (_) => EmployeeSettingsCubit()),
        BlocProvider(create: (_) => EmployeeNotificationCubit()),
        BlocProvider(create: (_) => MapCubit()),        
        BlocProvider(create: (_) => AiReviewCubit(sl<AiReviewRepository>())..loadPendingReviews()),
        BlocProvider(create: (_) => sl<AuthCubit>()..checkSession()),
        BlocProvider(create: (_) => sl<ReceiptCubit>()), // Added ReceiptCubit based on import and common pattern
      ],
      child: MaterialApp(
        title: 'WMS App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRouter.landing,
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}
