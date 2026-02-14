import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:wms/core/widgets/layout/admin_app_bar.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final user = state is Authenticated ? state.user : null;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AdminAppBar(title: 'Profil Administrateur'),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Color(0xFFE8F4F8),
                  child: Icon(Icons.person, size: 50, color: Color(0xFF4A9B9F)),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.fullName ?? 'Administrateur',
                  style: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  user?.email ?? 'admin@mobai.com',
                  style: GoogleFonts.lato(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                _buildInfoCard(
                  title: 'Informations de Compte',
                  items: [
                    _buildInfoItem(Icons.badge_outlined, 'Rôle', 'ADMIN'),
                    _buildInfoItem(Icons.business_outlined, 'Département', 'Management'),
                    _buildInfoItem(Icons.calendar_today_outlined, 'Membre depuis', 'Janvier 2026'),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => context.read<AuthCubit>().logout(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Se déconnecter'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard({required String title, required List<Widget> items}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...items,
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF4A9B9F)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[500])),
              Text(value, style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
