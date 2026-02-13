import 'package:flutter/material.dart';
import 'package:wms/features/warehouse/data/models/task_model.dart';
import 'package:wms/features/warehouse/presentation/pages/supervisor/supervisor_dashboard_screen.dart';
import 'package:wms/features/warehouse/presentation/pages/employee/employee_dashboard_screen.dart';
import 'package:wms/features/warehouse/presentation/pages/employee_main_screen.dart';
import 'package:wms/features/warehouse/presentation/pages/employee_profile_screen.dart';
import 'package:wms/features/warehouse/presentation/pages/employee_settings_screen.dart';
import 'package:wms/features/warehouse/presentation/pages/employee_notifications_screen.dart';
import 'package:wms/features/warehouse/presentation/pages/employee/task_detail_screen.dart';
import 'package:wms/features/warehouse/presentation/pages/supervisor/ai_review_screen.dart';
import 'package:wms/features/warehouse/presentation/pages/employee/log_task_screen.dart';
import 'package:wms/features/warehouse/presentation/pages/supervisor/supervisor_map_screen.dart';
import 'package:wms/features/warehouse/presentation/pages/supervisor/supervisor_notifications_screen.dart';
import 'package:wms/features/warehouse/presentation/pages/supervisor/supervisor_profile_screen.dart';

import 'package:wms/features/auth/presentation/pages/landing_page.dart';
import 'package:wms/features/auth/presentation/pages/onboarding_screen.dart';
import 'package:wms/features/auth/presentation/pages/role_selection_screen.dart';
import 'package:wms/features/auth/presentation/pages/login_screen.dart';

import 'package:wms/features/warehouse/presentation/pages/supervisor/flag_management_screen.dart';

import 'package:wms/features/warehouse/presentation/pages/supervisor/supervisor_settings_screen.dart';

class AppRouter {
  static const String landing = '/';
  static const String onboarding = '/onboarding';
  static const String roleSelection = '/role_selection';
  static const String login = '/login';
  static const String supervisorDashboard = '/supervisor/dashboard';
  static const String supervisorMap = '/supervisor/map';
  static const String supervisorAiReview = '/supervisor/ai_review';
  static const String supervisorFlagged = '/supervisor/flagged';
  static const String supervisorSettings = '/supervisor/settings';
  static const String supervisorNotifications = '/supervisor/notifications';
  static const String supervisorProfile = '/supervisor/profile';
  static const String employeeDashboard = '/employee/dashboard';
  static const String employeeMain = '/employee/main';
  static const String employeeTaskDetail = '/employee/task_detail';
  static const String employeeProfile = '/employee/profile';
  static const String employeeSettings = '/employee/settings';
  static const String employeeNotifications = '/employee/notifications';
  static const String logTask = '/employee/log_task';
  static const String adminDashboard = '/admin/dashboard'; // Placeholder

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case landing:
        return MaterialPageRoute(builder: (_) => const LandingPage());
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case roleSelection:
        return MaterialPageRoute(builder: (_) => const RoleSelectionScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case supervisorDashboard:
        return MaterialPageRoute(builder: (_) => const SupervisorDashboardScreen());
      case supervisorMap:
        return MaterialPageRoute(builder: (_) => const SupervisorMapScreen());
      case supervisorAiReview:
        return MaterialPageRoute(builder: (_) => const AiReviewScreen());
      case supervisorFlagged:
        return MaterialPageRoute(builder: (_) => const FlagManagementScreen());
      case supervisorSettings:
        return MaterialPageRoute(builder: (_) => const SupervisorSettingsScreen());
      case supervisorNotifications:
        return MaterialPageRoute(builder: (_) => const SupervisorNotificationsScreen());
      case supervisorProfile:
        return MaterialPageRoute(builder: (_) => const SupervisorProfileScreen());
      case employeeDashboard: // Legacy or direct link to dashboard only
        return MaterialPageRoute(builder: (_) => const EmployeeDashboardScreen());
      case employeeMain: // The new Main Wrapper
        return MaterialPageRoute(builder: (_) => const EmployeeMainScreen());
      case employeeProfile:
        return MaterialPageRoute(builder: (_) => const EmployeeProfileScreen());
      case employeeSettings:
        return MaterialPageRoute(builder: (_) => const EmployeeSettingsScreen());
      case employeeNotifications:
        return MaterialPageRoute(builder: (_) => const EmployeeNotificationsScreen());
      case employeeTaskDetail:
        final task = settings.arguments as TaskModel;
        return MaterialPageRoute(builder: (_) => EmployeeTaskDetailScreen(task: task));
      case logTask:
        return MaterialPageRoute(builder: (_) => const LogTaskScreen());
      default:
        return MaterialPageRoute(
            builder: (_) => Scaffold(
                  body: Center(child: Text('No route defined for ${settings.name}')),
                ));
    }
  }
}
