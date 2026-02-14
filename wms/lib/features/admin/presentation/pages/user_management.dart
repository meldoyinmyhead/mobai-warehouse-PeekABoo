import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/core/theme/app_theme.dart';
import 'package:wms/core/widgets/layout/admin_app_bar.dart';
import 'package:wms/features/admin/presentation/cubits/admin_user_cubit.dart';
import 'package:wms/features/auth/data/user_model.dart';
import 'package:wms/core/di/dependency_injection.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AdminUserCubit>()..loadUsers(),
      child: Scaffold(
        backgroundColor: AppTheme.veryLightGrey,
        appBar: AdminAppBar(title: 'Gestion des Utilisateurs'),
        body: BlocBuilder<AdminUserCubit, AdminUserState>(
        builder: (context, state) {
          if (state is AdminUserLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is AdminUserError) {
            return Center(child: Text(state.message));
          } else if (state is AdminUserLoaded) {
            final filteredUsers = _getFilteredUsers(state.users);
            return Column(
              children: [
                _buildHeader(state.users.length),
                _buildFilters(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      return _buildUserCard(filteredUsers[index]);
                    },
                  ),
                ),
              ],
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildHeader(int total) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Équipe MobAI', style: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('$total membres au total', style: GoogleFonts.lato(fontSize: 14, color: Colors.grey[600])),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/admin/create_user'),
                icon: const Icon(Icons.person_add_alt_1, size: 20, color: Colors.white),
                label: const Text('Nouvel Utilisateur', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Rechercher par nom ou email...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFFF1F4F6),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip('ALL', 'Tous'),
          _buildFilterChip('ADMIN', 'Admins'),
          _buildFilterChip('SUPERVISOR', 'Superviseurs'),
          _buildFilterChip('EMPLOYEE', 'Employés'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87)),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) setState(() => _selectedFilter = value);
        },
        selectedColor: AppTheme.primaryTeal,
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryTeal.withOpacity(0.1),
            child: Text(user.fullName[0], style: TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName, style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(user.email, style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getRoleColor(user.role).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user.role.name,
              style: TextStyle(color: _getRoleColor(user.role), fontWeight: FontWeight.bold, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.ADMIN: return Colors.purple;
      case UserRole.SUPERVISOR: return Colors.orange;
      case UserRole.EMPLOYEE: return AppTheme.primaryTeal;
    }
  }

  List<UserModel> _getFilteredUsers(List<UserModel> users) {
    List<UserModel> filtered = users;
    if (_selectedFilter != 'ALL') {
      filtered = filtered.where((u) => u.role.name == _selectedFilter).toList();
    }
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((u) => u.fullName.toLowerCase().contains(query) || u.email.toLowerCase().contains(query)).toList();
    }
    return filtered;
  }
}