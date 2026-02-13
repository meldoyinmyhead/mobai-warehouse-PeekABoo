import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms/features/warehouse/presentation/cubits/employee/employee_settings_cubit.dart';

class EmployeeSettingsScreen extends StatelessWidget {
  const EmployeeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
         leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Teal background top part
          Container(
            height: 100,
            color: Colors.teal,
          ),
           // Content
           SingleChildScrollView(
             padding: const EdgeInsets.all(16),
             child: Column(
               children: [
                 // Top Card (Mocked Image/Illustration)
                 Container(
                   height: 150,
                   width: double.infinity,
                   decoration: BoxDecoration(
                     color: Colors.teal[800],
                     borderRadius: BorderRadius.circular(16),
                     image: const DecorationImage(
                       image: NetworkImage('https://via.placeholder.com/300x150'), // Placeholder for illustration
                       fit: BoxFit.cover,
                       opacity: 0.2
                     )
                   ),
                   child: const Center(
                     child: Text("Personalize your settings", style: TextStyle(color: Colors.white70)),
                   ),
                 ),
                 const SizedBox(height: 16),
                 
                 BlocBuilder<EmployeeSettingsCubit, EmployeeSettingsState>(
                   builder: (context, state) {
                     if (state is EmployeeSettingsLoaded) {
                       return Column(
                         children: [
                           _buildCard(
                             title: 'Notifications',
                             icon: Icons.notifications_outlined,
                             children: [
                               SwitchListTile(
                                 title: const Text('Enable Notifications'),
                                 subtitle: const Text('Receive task updates and alerts'),
                                 value: state.notificationsEnabled,
                                 activeColor: Colors.teal,
                                 onChanged: (val) => context.read<EmployeeSettingsCubit>().toggleNotifications(val),
                               ),
                               Container(
                                 padding: const EdgeInsets.all(12),
                                 margin: const EdgeInsets.symmetric(horizontal: 16),
                                 decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
                                 child: const Text('Notifications must remain enabled for supervisor tracking', style: TextStyle(fontSize: 12, color: Colors.grey)),
                               )
                             ]
                           ),
                           const SizedBox(height: 16),
                            _buildCard(
                             title: 'Location Services',
                             icon: Icons.location_on_outlined,
                             children: [
                               SwitchListTile(
                                 title: const Row(children: [Text('Always Active'), SizedBox(width: 8), Icon(Icons.lock, size: 14, color: Colors.grey)]),
                                 subtitle: const Text('Location tracking is enabled'),
                                 value: state.locationEnabled,
                                 activeColor: Colors.teal,
                                 onChanged: (val) => context.read<EmployeeSettingsCubit>().toggleLocation(val),
                               ),
                                Container(
                                 padding: const EdgeInsets.all(12),
                                 margin: const EdgeInsets.symmetric(horizontal: 16),
                                 decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                                 child: const Text('Location required for supervisor monitoring - cannot be disabled', style: TextStyle(fontSize: 12, color: Colors.red)),
                               )
                             ]
                           ),
                           const SizedBox(height: 16),
                           _buildCard(
                             title: 'App Preferences',
                             icon: Icons.language, // Using globe icon substitute
                             children: [
                               ListTile(
                                 title: const Text('Language'),
                                 subtitle: Text(state.language),
                                 trailing: const Icon(Icons.chevron_right),
                                 onTap: () {},
                               ),
                               SwitchListTile(
                                 title: const Text('Dark Mode'),
                                 subtitle: const Text('Switch to dark theme'),
                                 value: state.darkModeEnabled,
                                 onChanged: (val) => context.read<EmployeeSettingsCubit>().toggleDarkMode(val),
                               ),
                                ListTile(
                                 title: const Text('Default View'),
                                 subtitle: const Text('Home Dashboard'),
                                 trailing: const Icon(Icons.chevron_right),
                                 onTap: () {},
                               ),
                             ]
                           ),
                           const SizedBox(height: 16),
                           _buildCard(
                             title: 'About',
                             icon: Icons.info_outline,
                             children: [
                               const ListTile(title: Text('App Version'), trailing: Text('1.0.0', style: TextStyle(fontWeight: FontWeight.bold))),
                               const ListTile(title: Text('Terms of Service'), trailing: Icon(Icons.chevron_right)),
                               const ListTile(title: Text('Privacy Policy'), trailing: Icon(Icons.chevron_right)),
                             ]
                           ),
                            const SizedBox(height: 24),
                            const Text('Version 1.0.0 Developed By MobAI', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            const Text('© 2026 BMS ELEC. All rights reserved.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 24),
                         ],
                       );
                     }
                     return const SizedBox.shrink();
                   },
                 )
               ],
             ),
           )
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Colors.teal),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
