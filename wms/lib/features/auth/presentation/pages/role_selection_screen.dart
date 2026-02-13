import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/core/theme/app_theme.dart';
import 'package:wms/features/auth/data/user_model.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Role selection', style: GoogleFonts.lato(color: Colors.grey[600], fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Image.asset('assets/images/role_selection.png', height: 200, errorBuilder: (c,e,s) => 
               const Icon(Icons.group_work, size: 100, color: AppTheme.lightBlue)
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome!',
              style: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.yellow),
            ),
            const SizedBox(height: 8),
            Text(
              'Please select your role to continue',
              style: GoogleFonts.lato(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 48),
            
            _buildRoleCard(
              context,
              title: 'Employee',
              subtitle: 'Manage warehouse tasks and operations',
              icon: Icons.person_outline,
              onTap: () {
                // We can pass the role as an argument if needed, or just let Login handle it via Auth logic.
                // For this UI flow, it seems to just filter or direct. Here we just go to Login.
                Navigator.pushNamed(context, '/login', arguments: {'role': 'employee'});
              },
            ),
            const SizedBox(height: 24),
             _buildRoleCard(
              context,
              title: 'Supervisor',
              subtitle: 'Monitor teams, approve AI, and manage flags',
              icon: Icons.admin_panel_settings_outlined,
              onTap: () {
                 Navigator.pushNamed(context, '/login', arguments: {'role': 'supervisor'});
              },
            ),

            const Spacer(),
            Text(
              'Version 1.0.0 Developed by MobAI\n© 2026 BBMS ELEC. All rights reserved.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(fontSize: 10, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
             BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.lightBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.lightBlue, size: 28),
            ),
            const SizedBox(width: 16),
             Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkBlue)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: GoogleFonts.lato(fontSize: 13, color: Colors.grey[600])),
                ],
              ),
            ),
             const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
