import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms/features/auth/presentation/cubits/employee_settings_cubit.dart';

class EmployeeSettingsScreen extends StatelessWidget {
  const EmployeeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
      
        child: Column(
          children: [
            // Image below AppBar
            Container(

              height: 170,
              width:MediaQuery.of(  context).size.width,
              decoration: BoxDecoration(
            
                image:  DecorationImage(
                  image: AssetImage("assets/images/settings.png"),
                  fit: BoxFit.cover
                ),
              ),
              
              ),
            

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.all(12.0),
              child: BlocBuilder<EmployeeSettingsCubit, EmployeeSettingsState>(
                builder: (context, state) {
                  if (state is EmployeeSettingsLoaded) {
                    return Column(
                      children: [
                        _buildCard(
                          title: 'Notifications',
                          icon: Icons.notifications_outlined,
                          children: [
                            SwitchListTile(
                              title: const Text('Activer les notifications'),
                              subtitle: const Text(
                                'Recevez les mises à jour et alertes des tâches',
                              ),
                              value: state.notificationsEnabled,
                           
                              onChanged: (val) => context
                                  .read<EmployeeSettingsCubit>()
                                  .toggleNotifications(val),
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Les notifications doivent rester activées pour le suivi du superviseur',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildCard(
                          title: 'Services de localisation',
                          icon: Icons.location_on_outlined,
                          children: [
                            SwitchListTile(
                              title: const Row(
                                children: [
                                  Text('Toujours actif'),
                                  SizedBox(width: 8),
                                  Icon(
                                    Icons.lock,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                              subtitle: const Text(
                                'Le suivi de localisation est activé',
                              ),
                              value: state.locationEnabled,
                              
                              onChanged: (val) => context
                                  .read<EmployeeSettingsCubit>()
                                  .toggleLocation(val),
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'La localisation est requise pour la surveillance du superviseur - ne peut pas être désactivée',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildCard(
                          title: 'Préférences de l\'application',
                          icon: Icons.language,
                          children: [
                            ListTile(
                              title: const Text('Langue'),
                              subtitle: Text(state.language),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {},
                            ),
                            SwitchListTile(
                              title: const Text('Mode sombre'),
                              subtitle: const Text('Passer au thème sombre'),
                              value: state.darkModeEnabled,
                              onChanged: (val) => context
                                  .read<EmployeeSettingsCubit>()
                                  .toggleDarkMode(val),
                            ),
                            ListTile(
                              title: const Text('Vue par défaut'),
                              subtitle: const Text('Tableau de bord'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildCard(
                          title: 'À propos',
                          icon: Icons.info_outline,
                          children: [
                            const ListTile(
                              title: Text('Version de l\'application'),
                              trailing: Text(
                                '1.0.0',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const ListTile(
                              title: Text('Conditions d\'utilisation'),
                              trailing: Icon(Icons.chevron_right),
                            ),
                            const ListTile(
                              title: Text('Politique de confidentialité'),
                              trailing: Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Version 1.0.0 Développé par MobAI',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const Text(
                          '© 2026 BMS ELEC. Tous droits réservés.',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Colors.teal),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
