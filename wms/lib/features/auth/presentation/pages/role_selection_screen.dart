import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/core/theme/app_theme.dart';
import 'package:wms/core/routes/app_router.dart';
import 'package:wms/features/auth/data/user_model.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  static const List<Map<String, dynamic>> _roles = [
    {
      'key': 'employee',
      'title': 'Employee',
      'subtitle': 'Manage warehouse tasks and operations.',
      'icon': Icons.person_outline,
    },
    {
      'key': 'supervisor',
      'title': 'Supervisor',
      'subtitle': 'Monitor teams, approve AI, and manage flags',
      'icon': Icons.groups_outlined,
    },
    {
      'key': 'admin',
      'title': 'Admin',
      'subtitle': 'Manage users, analytics, and system settings.',
      'icon': Icons.admin_panel_settings_outlined,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.veryLightGrey,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Central illustration (no rounded container, no yellow background)
                    Center(
                      child: Image.asset(
                        'assets/images/amico.png',
                        height: 180,
                        width: 180,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(
                          height: 180,
                          width: 180,
                          color: AppTheme.lightBlue.withOpacity(0.1),
                          child: const Icon(
                            Icons.warehouse,
                            size: 64,
                            color: AppTheme.lightBlue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Welcome!',
                        style: GoogleFonts.lato(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.yellow,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Please select your role to continue',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          color: AppTheme.mediumGrey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ..._roles.map((role) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildRoleCard(
                        context,
                        title: role['title'] as String,
                        subtitle: role['subtitle'] as String,
                        icon: role['icon'] as IconData,
                        onTap: () => _navigateToLogin(context, role['key'] as String),
                      ),
                    )),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                children: [
                  Text(
                    'Version 1.0.0 Developed by Mobini',
                    style: GoogleFonts.lato(fontSize: 11, color: AppTheme.lightGrey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '© 2026 IENE ELEC. All rights reserved.',
                    style: GoogleFonts.lato(fontSize: 11, color: AppTheme.lightGrey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToLogin(BuildContext context, String roleKey) {
    UserRole role = UserRole.EMPLOYEE;
    if (roleKey == 'supervisor') role = UserRole.SUPERVISOR;
    if (roleKey == 'admin') role = UserRole.ADMIN;
    Navigator.pushNamed(context, AppRouter.login, arguments: {'role': role.name.toLowerCase()});
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppTheme.lightGrey.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppTheme.lightBlue, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        color: AppTheme.mediumGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.lightBlue),
            ],
          ),
        ),
      ),
    );
  }
}
