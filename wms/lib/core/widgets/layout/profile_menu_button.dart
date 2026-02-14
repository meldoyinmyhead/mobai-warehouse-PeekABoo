import 'package:flutter/material.dart';
import 'package:wms/core/theme/app_theme.dart';

class ProfileMenuButton extends StatelessWidget {
  final String profileRoute;
  final String logoutRoute;

  const ProfileMenuButton({
    super.key,
    this.profileRoute = '/employee/profile',
    this.logoutRoute = '/login',
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      icon: CircleAvatar(
        backgroundColor: Colors.white,
        child: const Icon(Icons.person_outline, color: Color(0xFF5D6266)),
      ),
      onSelected: (value) {
        if (value == 'profile') {
          Navigator.pushNamed(context, profileRoute);
        } else if (value == 'logout') {
          Navigator.pushNamedAndRemoveUntil(context, logoutRoute, (route) => false);
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline, color: Colors.grey, size: 20),
              SizedBox(width: 12),
              Text('View Full Profile', style: TextStyle(color: Colors.black87)),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: AppTheme.red, size: 20),
              SizedBox(width: 12),
              Text('Log Out', style: TextStyle(color: AppTheme.red)),
            ],
          ),
        ),
      ],
    );
  }
}
