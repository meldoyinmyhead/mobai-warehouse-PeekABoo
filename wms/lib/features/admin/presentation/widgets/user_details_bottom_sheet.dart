import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/core/theme/app_theme.dart';
import 'package:wms/features/auth/data/user_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms/features/admin/presentation/cubits/admin_user_cubit.dart';

class UserDetailsBottomSheet extends StatefulWidget {
  final UserModel user;
  const UserDetailsBottomSheet({super.key, required this.user});

  @override
  State<UserDetailsBottomSheet> createState() => _UserDetailsBottomSheetState();
}

class _UserDetailsBottomSheetState extends State<UserDetailsBottomSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProfileTab(),
                _buildPerformanceTab(),
                _buildActivityTab(),
              ],
            ),
          ),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFFE8F4F8),
            child: Text(
              widget.user.fullName.isEmpty ? '?' : widget.user.fullName.substring(0, 1).toUpperCase(),
              style: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF4A9B9F)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.user.fullName, style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('EMP-001', style: GoogleFonts.lato(fontSize: 14, color: Colors.grey[500])),
                const SizedBox(height: 4),
                _buildRoleBadge(widget.user.role),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(UserRole role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: role == UserRole.EMPLOYEE ? Colors.green[100] : Colors.blue[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        role.name,
        style: GoogleFonts.lato(fontSize: 10, fontWeight: FontWeight.bold, color: role == UserRole.EMPLOYEE ? Colors.green[800] : Colors.blue[800]),
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      labelColor: const Color(0xFF4A9B9F),
      unselectedLabelColor: Colors.grey,
      indicatorColor: const Color(0xFF4A9B9F),
      labelStyle: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold),
      tabs: const [
        Tab(text: 'PROFILE'),
        Tab(text: 'PERFORMANCE'),
        Tab(text: 'ACTIVITY'),
      ],
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildInfoField('Full Name', widget.user.fullName),
          _buildInfoField('Employee ID', 'EMP-001'),
          _buildInfoField('E-mail', widget.user.email),
          _buildInfoField('Téléphone', '+1234567890'),
          _buildInfoField('Département', 'Opérations d\'entrepôt'),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBigStat('234', 'Tasks Completed'),
              _buildBigStat('97%', 'Accuracy Rate'),
            ],
          ),
          const SizedBox(height: 24),
          _buildInfoField('Average Task Duration', '12.5 mins'),
          _buildInfoField('Flags Raised', '3', color: Colors.orange),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildActivityItem('Completed task #RCP-001', '2 hours ago', Colors.green),
        _buildActivityItem('Logged in', '3 hours ago', Colors.blue),
        _buildActivityItem('Flagged issue on task #STR-045', '5 hours ago', Colors.orange),
      ],
    );
  }

  Widget _buildInfoField(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
            child: Text(value, style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildBigStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.lato(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF2C3E50))),
        Text(label, style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildActivityItem(String title, String time, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: GoogleFonts.lato(fontSize: 14))),
          Text(time, style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () {
                final updatedUser = widget.user.copyWith(isActive: !widget.user.isActive);
                context.read<AdminUserCubit>().updateUser(updatedUser);
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: widget.user.isActive ? Colors.red : Colors.green),
                foregroundColor: widget.user.isActive ? Colors.red : Colors.green,
              ),
              child: Text(widget.user.isActive ? 'DISABLE' : 'ENABLE'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF4A9B9F)),
                foregroundColor: const Color(0xFF4A9B9F),
              ),
              child: const Text('EDIT'),
            ),
          ),
        ],
      ),
    );
  }
}
