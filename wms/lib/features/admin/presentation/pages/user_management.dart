import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/core/theme/app_theme.dart';
import 'package:wms/core/widgets/adminBottomBar.dart';
import 'package:wms/core/widgets/layout/supervisorBottonBar.dart';
import 'package:wms/features/admin/presentation/pages/admin_dashboard_screen.dart';
import 'package:wms/features/admin/presentation/pages/analysis.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
   int _currentIndex = 1;

  void _onNavBarTap(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminDashboardScreen()),
        );
        break;

      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => UserManagementScreen()),
        );
      
        break;
        
      case 2:
         
      
        break;
      case 3:
          Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) =>AnalyticsScreen()),
        );
        break;
    }
  }
  String _selectedFilter = 'TOUS';
  final TextEditingController _searchController = TextEditingController();

  final List<UserData> _users = [
    UserData(
      name: 'John Doe',
      initials: 'JD',
      role: 'EMPLOYÉ',
      roleColor: Color(0xFF5D6266),
      id: 'EMP-003',
      status: 'Active',
      lastActive: 'Il y a 2 mins',
      tasks: 234,
      accuracy: 99,
    ),
    UserData(
      name: 'Sarah Smith',
      initials: 'SS',
      role: 'SUPERVISEUR',
      roleColor: Color(0xFF4A9B9F),
      id: 'SUP-012',
      status: 'Active',
      lastActive: 'Il y a 5 mins',
      tasks: 456,
      accuracy: 98,
    ),
    UserData(
      name: 'Michael Johnson',
      initials: 'MJ',
      role: 'ADMIN',
      roleColor: Color(0xFFFDB913),
      id: 'ADM-004',
      status: 'Active',
      lastActive: 'Just now',
      tasks: 123,
      accuracy: 100,
    ),
    UserData(
      name: 'Emily Davis',
      initials: 'ED',
      role: 'EMPLOYÉ',
      roleColor: Color(0xFF5D6266),
      id: 'EMP-008',
      status: 'Offline',
      lastActive: 'Il y a 2 heures',
      tasks: 189,
      accuracy: 95,
    ),
  ];

  List<UserData> get _filteredUsers {
    if (_selectedFilter == 'TOUS') return _users;
    return _users.where((user) {
      switch (_selectedFilter) {
        case 'ADMIN':
          return user.role == 'ADMIN';
        case 'SUPERVISEUR':
          return user.role == 'SUPERVISEUR';
        case 'EMPLOYÉ':
          return user.role == 'EMPLOYÉ';
        default:
          return true;
      }
    }).toList();
  }

  int get _totalUsers => _users.length;
  int get _activeToday => _users.where((u) => u.status == 'Active').length;
  int get _pending => 0;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.veryLightGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(12.0),
          child: GestureDetector(
            onTap: () {},
            child: const CircleAvatar(
              backgroundColor: Color(0xFFF5F5F5),
              child: Icon(Icons.person_outline, color: Color(0xFF5D6266)),
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', height: 30),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: Color(0xFF5D6266),
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF5D6266),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFB8D5DD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestion des utilisateurs',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gérer tous les utilisateurs du système\net les permissions',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: const Color(0xFF5D6266),
                  ),
                ),
                const SizedBox(height: 16),

                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher par nom, ID, email...',
                      hintStyle: GoogleFonts.lato(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('TOUS'),
                      const SizedBox(width: 8),
                      _buildFilterChip('ADMIN'),
                      const SizedBox(width: 8),
                      _buildFilterChip('SUPERVISEUR'),
                      const SizedBox(width: 8),
                      _buildFilterChip('EMPLOYÉ'),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn(_totalUsers.toString(), 'Total Users'),
                    _buildStatColumn(_activeToday.toString(), 'Active Today', color: Colors.green),
                    _buildStatColumn(_pending.toString(), 'Pending'),
                  ],
                ),
              ],
            ),
          ),

          // User List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                return _buildUserCard(_filteredUsers[index]);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new user
        },
        backgroundColor: const Color(0xFFFDB913),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      bottomNavigationBar: AdminBottomBar(
          currentIndex: _currentIndex,
          onTap: _onNavBarTap,
        ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4A9B9F) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF4A9B9F) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.lato(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color ?? const Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 11,
            color: const Color(0xFF5D6266),
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(UserData user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFE8F4F8),
            child: Text(
              user.initials,
              style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4A9B9F),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.name,
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: user.roleColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        user.role,
                        style: GoogleFonts.lato(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  user.id,
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: user.status == 'Active' 
                          ? Colors.green 
                          : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${user.status} • ${user.lastActive}',
                      style: GoogleFonts.lato(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.task_alt, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${user.tasks} tasks',
                      style: GoogleFonts.lato(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${user.accuracy}% accuracy',
                      style: GoogleFonts.lato(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class UserData {
  final String name;
  final String initials;
  final String role;
  final Color roleColor;
  final String id;
  final String status;
  final String lastActive;
  final int tasks;
  final int accuracy;

  UserData({
    required this.name,
    required this.initials,
    required this.role,
    required this.roleColor,
    required this.id,
    required this.status,
    required this.lastActive,
    required this.tasks,
    required this.accuracy,
  });
}