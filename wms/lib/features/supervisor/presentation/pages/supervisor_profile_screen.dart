import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/core/theme/app_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:wms/core/routes/app_router.dart';

class SupervisorProfileScreen extends StatefulWidget {
  const SupervisorProfileScreen({super.key});

  @override
  State<SupervisorProfileScreen> createState() =>
      _SupervisorProfileScreenState();
}

class _SupervisorProfileScreenState extends State<SupervisorProfileScreen> {
  // Sample supervisor data
  final String _name = 'Mobina Sadat';
  final String _firstName = 'Mobina';
  final String _lastName = 'Sadat';
  final String _supervisorId = 'SUP-2024-031';
  final String _department = 'Warehouse Operations';
  final String _role = 'Warehouse Supervisor';
  final String _email = 'mobina.sadat@bms.com';
  final String _phone = '+971 50 123 4567';

  // Controllers for editing
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: _email);
    _phoneController = TextEditingController(text: _phone);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        String name = '';
        String email = '';
        String userId = '';
        String role = '';
        bool isActive = true;

        if (state is Authenticated) {
          name = state.user.fullName;
          email = state.user.email;
          userId = state.user.id;
          role = state.user.role.name;
          isActive = state.user.isActive;
        }

        if (!_isEditing) {
          _emailController.text = email;
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(
              'Profil',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Header Card
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name.isNotEmpty ? name : 'Utilisateur',
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        role,
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                       const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isActive ? Colors.green : Colors.red),
                        ),
                        child: Text(
                          isActive ? 'Actif' : 'Inactif',
                          style: GoogleFonts.lato(
                            fontSize: 10,
                            color: isActive ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Personal Information Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: _buildProfileCard(
                    title: 'Informations personnelles',
                    icon: Icons.person_outline,
                    children: [
                      _buildPersonalField('Nom complet', name),
                      const SizedBox(height: 12),
                      _buildPersonalFieldWithIndicator(
                        'ID Utilisateur',
                        userId,
                      ),
                      const SizedBox(height: 12),
                      _buildPersonalField('Email', email),
                    ],
                  ),
                ),

                // Work Information Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: _buildProfileCard(
                    title: 'Informations de compte',
                    icon: Icons.work_outline,
                    children: [
                      _buildWorkField('Rôle', role),
                      const SizedBox(height: 12),
                      _buildWorkField('Statut', isActive ? 'Actif' : 'Inactif'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Logout Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.read<AuthCubit>().logout();
                        Navigator.pushNamedAndRemoveUntil(context, AppRouter.landing, (route) => false);
                      },
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: Text(
                        'Se déconnecter',
                        style: GoogleFonts.lato(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileCard({
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

  Widget _buildPersonalField(String label, String value) {
    bool isEditable = _isEditing && (label == 'Email' || label == 'Phone');
    TextEditingController? controller;

    if (label == 'Email') {
      controller = _emailController;
    } else if (label == 'Phone') {
      controller = _phoneController;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isEditable ? Colors.white : Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isEditable ? AppTheme.darkBlue : Colors.grey[200]!,
          width: isEditable ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          if (isEditable && controller != null)
            TextField(
              controller: controller,
              style: GoogleFonts.lato(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            )
          else
            Text(
              value,
              style: GoogleFonts.lato(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPersonalFieldWithIndicator(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppTheme.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkField(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label + ':',
          style: GoogleFonts.lato(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.lato(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
