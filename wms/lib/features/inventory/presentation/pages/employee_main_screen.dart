import 'package:flutter/material.dart';
import 'package:wms/features/inventory/presentation/pages/employee_dashboard_screen.dart';
import 'package:wms/features/logistics/presentation/pages/employee_all_tasks_screen.dart';
import 'package:wms/core/widgets/layout/modern_floating_navbar.dart';
import 'package:wms/core/routes/app_router.dart';

class EmployeeMainScreen extends StatefulWidget {
  const EmployeeMainScreen({super.key});

  @override
  State<EmployeeMainScreen> createState() => _EmployeeMainScreenState();
}

class _EmployeeMainScreenState extends State<EmployeeMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const EmployeeDashboardScreen(),
    const SizedBox(), // Placeholder for Log
    const EmployeeAllTasksScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.pushNamed(context, AppRouter.logTask);
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _pages[_currentIndex],
      bottomNavigationBar: ModernFloatingNavbar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
