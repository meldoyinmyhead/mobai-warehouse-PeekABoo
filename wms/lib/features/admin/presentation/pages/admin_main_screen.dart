import 'package:flutter/material.dart';
import 'package:wms/features/admin/presentation/pages/admin_dashboard_screen.dart';
import 'package:wms/features/admin/presentation/pages/user_management.dart';
import 'package:wms/features/admin/presentation/pages/admin_settings_view.dart';
import 'package:wms/features/admin/presentation/pages/admin_analytics_view.dart';
import 'package:wms/core/widgets/layout/admin_bottom_bar.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _pages = [
    const AdminDashboardScreen(isView: true),
    const UserManagementScreen(),
    const AdminSettingsView(),
    const AdminAnalyticsView(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
      ),
      extendBody: true,
      floatingActionButton: _currentIndex == 1 || _currentIndex == 0 ? Padding(
        padding: const EdgeInsets.only(bottom: 12), // Tucked right above the navbar
        child: FloatingActionButton(
          onPressed: () {
            if (_currentIndex == 1) {
               Navigator.pushNamed(context, '/admin/create_user');
            } else {
               Navigator.pushNamed(context, '/admin/create_warehouse');
            }
          },
          backgroundColor: const Color(0xFFFDB913),
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: AdminBottomBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
