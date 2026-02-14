import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/core/theme/app_theme.dart';
import 'package:wms/core/widgets/layout/admin_bottom_bar.dart';
import 'package:wms/core/widgets/layout/supervisorBottonBar.dart';
import 'package:wms/features/admin/presentation/pages/admin_dashboard_screen.dart';
import 'package:wms/features/admin/presentation/pages/user_management.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 3;
  String _selectedTimeFilter = 'SEMAINE';
  String _selectedCategoryFilter = 'Performance IA';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

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
        Navigator.pushReplacementNamed(context, '/admin/reports');
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AnalyticsScreen()),
        );
        break;
    }
  }

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
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Analytiques & Rapports',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Informations et métriques\ncomplètes du système',
                        style: GoogleFonts.lato(
                          fontSize: 11,
                          color: const Color(0xFF5D6266),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey[600],
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
              ),
              labelStyle: GoogleFonts.lato(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'AUJOURD\'HUI'),
                Tab(text: 'SEMAINE'),
                Tab(text: 'MOIS'),
                Tab(text: 'PERSONNALISÉ'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAIPerformanceTab(),
                _buildOperationsTab(),
                _buildUsersTab(),
                _buildInventoryTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Download report
        },
        backgroundColor: const Color(0xFF4A9B9F),
        child: const Icon(Icons.download, color: Colors.white),
      ),
      bottomNavigationBar: AdminBottomBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
      ),
    );
  }

  // AI Performance Tab
  Widget _buildAIPerformanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Performance IA', isCategory: true),
                const SizedBox(width: 8),
                _buildFilterChip('Utilisateurs', isCategory: true),
                const SizedBox(width: 8),
                _buildFilterChip('Utilisateur', isCategory: true),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Metrics Row
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  value: '324',
                  label: 'Total Utilisateurs',
                  icon: Icons.people_outline,
                  color: const Color(0xFF4A9B9F),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  value: '87%',
                  label: 'Utilisation IA',
                  icon: Icons.analytics_outlined,
                  color: const Color(0xFF27AE60),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  value: '12',
                  label: 'Remplacements',
                  icon: Icons.refresh,
                  color: const Color(0xFFFDB913),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Service Performance
          Text(
            'Performance du Service',
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          _buildProgressItem('Prévision', 87, const Color(0xFF4A9B9F)),
          const SizedBox(height: 8),
          _buildProgressItem('Optimisation Stockage', 94, const Color(0xFF27AE60)),
          const SizedBox(height: 8),
          _buildProgressItem('Itinéraires Cueillette', 78, const Color(0xFFFDB913)),
        ],
      ),
    );
  }

  // Operations Tab
  Widget _buildOperationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Opérations', isCategory: true),
                const SizedBox(width: 8),
                _buildFilterChip('Performance IA', isCategory: true),
                const SizedBox(width: 8),
                _buildFilterChip('Utilisateurs', isCategory: true),
                const SizedBox(width: 8),
                _buildFilterChip('Utilisateur', isCategory: true),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Metrics Row
          Row(
            children: [
              Expanded(
                child: _buildLargeMetricCard(
                  value: '169',
                  label: 'Total Tâches',
                  subValue: 'Actives',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLargeMetricCard(
                  value: '18m',
                  label: 'Temps Moy.',
                  subValue: 'Achèvement',
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Success Rate
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Taux de Réussite',
                        style: GoogleFonts.lato(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '92%',
                        style: GoogleFonts.lato(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF27AE60),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Meilleur Performeur',
                        style: GoogleFonts.lato(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '7',
                        style: GoogleFonts.lato(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF4A9B9F),
                        ),
                      ),
                      Text(
                        'Tâches/h',
                        style: GoogleFonts.lato(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Operations Breakdown
          Text(
            'Répartition des Opérations',
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          _buildOperationItem('Réception', 23, const Color(0xFF4A9B9F)),
          const SizedBox(height: 8),
          _buildOperationItem('Stockage', 45, const Color(0xFF27AE60)),
          const SizedBox(height: 8),
          _buildOperationItem('Cueillette', 67, const Color(0xFFFDB913)),
          const SizedBox(height: 8),
          _buildOperationItem('Livraison', 34, const Color(0xFFE74C3C)),
        ],
      ),
    );
  }

  // Users Tab
  Widget _buildUsersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Utilisateurs', isCategory: true),
                const SizedBox(width: 8),
                _buildFilterChip('Performance IA', isCategory: true),
                const SizedBox(width: 8),
                _buildFilterChip('Utilisateurs', isCategory: true),
                const SizedBox(width: 8),
                _buildFilterChip('Inventaire', isCategory: true),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Metrics Row
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  value: '99',
                  label: 'Utilisateurs Actifs',
                  icon: Icons.people_outline,
                  color: const Color(0xFF4A9B9F),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  value: '+5',
                  label: 'Nouveau Aujourd\'hui',
                  icon: Icons.person_add_outlined,
                  color: const Color(0xFF27AE60),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  value: '456',
                  label: 'Total Utilisateurs',
                  icon: Icons.groups_outlined,
                  color: const Color(0xFF5D6266),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Performance by Role
          Text(
            'Performance par Rôle',
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          _buildRolePerformance('Employé', '145 tâches', '93%'),
          const SizedBox(height: 8),
          _buildRolePerformance('Superviseur', '67 utilisateurs', '95%'),
          const SizedBox(height: 8),
          _buildRolePerformance('Admin', '18 tâches', '100%'),
        ],
      ),
    );
  }

  // Inventory Tab
  Widget _buildInventoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Inventaire', isCategory: true),
                const SizedBox(width: 8),
                _buildFilterChip('Performance IA', isCategory: true),
                const SizedBox(width: 8),
                _buildFilterChip('Utilisateurs', isCategory: true),
                const SizedBox(width: 8),
                _buildFilterChip('Inventaire', isCategory: true),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Metrics Row
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  value: '1.2K',
                  label: 'Total SKUs',
                  icon: Icons.inventory_2_outlined,
                  color: const Color(0xFF4A9B9F),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  value: '68%',
                  label: 'Capacité',
                  icon: Icons.pie_chart_outline,
                  color: const Color(0xFFFDB913),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Low-Stock Alerts
          Text(
            'Alertes de Stock Bas',
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          _buildAlertItem('Samsung Galaxy S23', 'Critique', const Color(0xFFE74C3C)),
          const SizedBox(height: 8),
          _buildAlertItem('Apple AirPods Pro', 'Bas', const Color(0xFFFDB913)),
          const SizedBox(height: 8),
          _buildAlertItem('Câbles USB-C', 'Avertissement', const Color(0xFFF39C12)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, {bool isCategory = false}) {
    final isSelected = isCategory
        ? _selectedCategoryFilter == label
        : _selectedTimeFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isCategory) {
            _selectedCategoryFilter = label;
          } else {
            _selectedTimeFilter = label;
          }
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
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
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
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.lato(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeMetricCard({
    required String value,
    required String label,
    required String subValue,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subValue,
            style: GoogleFonts.lato(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.lato(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4A9B9F),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(String label, int percentage, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              Text(
                '$percentage%',
                style: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationItem(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
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
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            count.toString(),
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRolePerformance(String role, String tasks, String accuracy) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4A9B9F).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              role == 'Employé'
                  ? Icons.person_outline
                  : role == 'Superviseur'
                      ? Icons.supervisor_account_outlined
                      : Icons.admin_panel_settings_outlined,
              color: const Color(0xFF4A9B9F),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role,
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  tasks,
                  style: GoogleFonts.lato(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            accuracy,
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF27AE60),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(String item, String level, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
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
          Icon(Icons.warning_amber_rounded, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item,
              style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              level,
              style: GoogleFonts.lato(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}