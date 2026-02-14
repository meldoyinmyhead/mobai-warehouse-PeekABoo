import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:wms/core/routes/app_router.dart';

class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const AdminAppBar({
    super.key,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12.0),
        child: PopupMenuButton<String>(
          offset: const Offset(0, 48),
          onSelected: (value) {
            if (value == 'profile') {
              Navigator.pushNamed(context, '/admin/profile');
            } else if (value == 'logout') {
              context.read<AuthCubit>().logout();
              Navigator.pushNamedAndRemoveUntil(context, AppRouter.landing, (route) => false);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person_outline, color: Color(0xFF5D6266), size: 18),
                  SizedBox(width: 12),
                  Text('Mon Profil'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.redAccent, size: 18),
                  SizedBox(width: 12),
                  Text('Déconnexion', style: TextStyle(color: Colors.redAccent)),
                ],
              ),
            ),
          ],
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Color(0xFFF5F5F5),
              child: Icon(Icons.person_outline, color: Color(0xFF5D6266), size: 24),
            ),
          ),
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.lato(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF2C3E50),
        ),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
