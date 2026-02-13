import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/core/theme/app_theme.dart';
import 'package:wms/features/auth/presentation/cubits/auth_cubit.dart';

class SupervisorSettingsScreen extends StatefulWidget {
  const SupervisorSettingsScreen({super.key});

  @override
  State<SupervisorSettingsScreen> createState() =>
      _SupervisorSettingsScreenState();
}

class _SupervisorSettingsScreenState extends State<SupervisorSettingsScreen> {
  // Notification Settings
  bool _enableNotifications = true;
  bool _pushAlerts = true;
  bool _emailReminders = true;
  bool _taskCompletionAlerts = true;
  bool _customAlerts = false;

  // AI Preferences
  bool _aiSuggestions = true;
  bool _livePerformance = true;
  bool _viewReasoningByDefault = false;
  bool _orderProcessing = true;

  // Status
  bool _dataSynced = true;
  bool _rateSynced = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Paramètres',
          style: GoogleFonts.lato(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Settings image header
            Container(
              height: 170,
              width: MediaQuery.of(context).size.width,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/settings.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notifications Card
                  _buildSettingsCard(
                    title: 'Notifications',
                    icon: Icons.notifications_outlined,
                    children: [
                      _buildSettingRow(
                        'Activer les notifications',
                        _enableNotifications,
                        (val) {
                          setState(() {
                            _enableNotifications = val;
                          });
                        },
                      ),
                      _buildSettingRow('Alertes push', _pushAlerts, (val) {
                        setState(() {
                          _pushAlerts = val;
                        });
                      }),
                      _buildSettingRow('Rappels par email', _emailReminders, (
                        val,
                      ) {
                        setState(() {
                          _emailReminders = val;
                        });
                      }),
                      _buildSettingRow(
                        'Alertes d\'achèvement des tâches',
                        _taskCompletionAlerts,
                        (val) {
                          setState(() {
                            _taskCompletionAlerts = val;
                          });
                        },
                      ),
                      _buildSettingRow(
                        'Alertes personnalisées',
                        _customAlerts,
                        (val) {
                          setState(() {
                            _customAlerts = val;
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // AI Preferences Card
                  _buildSettingsCard(
                    title: 'Préférences IA',
                    icon: Icons.smart_toy_outlined,
                    children: [
                      _buildSettingRow('Suggestions IA', _aiSuggestions, (val) {
                        setState(() {
                          _aiSuggestions = val;
                        });
                      }),
                      _buildSettingRow(
                        'Performance en direct',
                        _livePerformance,
                        (val) {
                          setState(() {
                            _livePerformance = val;
                          });
                        },
                      ),
                      _buildSettingRow(
                        'Afficher le raisonnement par défaut',
                        _viewReasoningByDefault,
                        (val) {
                          setState(() {
                            _viewReasoningByDefault = val;
                          });
                        },
                      ),
                      _buildSettingRow(
                        'Traitement des commandes',
                        _orderProcessing,
                        (val) {
                          setState(() {
                            _orderProcessing = val;
                          });
                        },
                      ),
                      _buildSettingMenuItem(
                        'Tableau de bord des performances IA',
                        () {},
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Status Card
                  _buildSettingsCard(
                    title: 'Statut',
                    icon: Icons.router_outlined,
                    children: [
                      _buildSettingRow('Données synchronisées', _dataSynced, (
                        val,
                      ) {
                        setState(() {
                          _dataSynced = val;
                        });
                      }),
                      _buildSettingRow('Tarifs synchronisés', _rateSynced, (
                        val,
                      ) {
                        setState(() {
                          _rateSynced = val;
                        });
                      }),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // About Card
                  _buildSettingsCard(
                    title: 'À propos',
                    icon: Icons.info_outlined,
                    children: [
                      _buildSettingMenuItem(
                        'Version de l\'application',
                        () {},
                        trailing: Text(
                          '1.0.0',
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      _buildSettingMenuItem('Conditions d\'utilisation', () {}),
                      _buildSettingMenuItem(
                        'Politique de confidentialité',
                        () {},
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle logout
                        context.read<AuthCubit>().logout();
                         Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        'SE DÉCONNECTER',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(icon, color: Colors.grey[600], size: 20),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(String title, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.lato(fontSize: 12, color: Colors.black87),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.darkBlue,
            inactiveThumbColor: Colors.grey[400],
            inactiveTrackColor: Colors.grey[300],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingMenuItem(
    String title,
    VoidCallback onTap, {
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.lato(fontSize: 12, color: Colors.black87),
            ),
            trailing ??
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 18),
          ],
        ),
      ),
    );
  }
}
