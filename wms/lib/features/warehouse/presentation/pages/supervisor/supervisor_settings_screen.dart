import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/core/theme/app_theme.dart';
import 'package:wms/features/auth/presentation/cubits/auth_cubit.dart';

class SupervisorSettingsScreen extends StatefulWidget {
  const SupervisorSettingsScreen({super.key});

  @override
  State<SupervisorSettingsScreen> createState() => _SupervisorSettingsScreenState();
}

class _SupervisorSettingsScreenState extends State<SupervisorSettingsScreen> {
  bool _isFrench = true;
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.veryLightGrey,
      appBar: AppBar(
        title: Text('Paramètres', style: GoogleFonts.lato(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Général'),
            _buildSettingsCard([
              _buildSwitchTile(
                'Langue (Français)',
                'Activer l\'interface en français',
                _isFrench,
                (val) => setState(() => _isFrench = val),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                'Notifications',
                'Recevoir des alertes en temps réel',
                _notificationsEnabled,
                (val) => setState(() => _notificationsEnabled = val),
              ),
            ]),
            const SizedBox(height: 24),
            _buildSectionHeader('Compte'),
            _buildSettingsCard([
              _buildActionTile(
                'Profil',
                Icons.person_outline,
                () {},
              ),
               const Divider(height: 1),
              _buildActionTile(
                'Aide & Support',
                Icons.help_outline,
                () {},
              ),
            ]),
             const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Logout Logic
                  context.read<AuthCubit>().logout();
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: Text(
                  'Se déconnecter',
                  style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Version 1.0.0 (Build 2026.02.13)',
                style: GoogleFonts.lato(color: Colors.grey[500], fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.lato(
          color: Colors.grey[600],
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title, style: GoogleFonts.lato(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(subtitle, style: GoogleFonts.lato(color: Colors.grey[500], fontSize: 13)),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.darkBlue,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildActionTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.darkBlue, size: 20),
      ),
      title: Text(title, style: GoogleFonts.lato(fontWeight: FontWeight.w600, fontSize: 15)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
