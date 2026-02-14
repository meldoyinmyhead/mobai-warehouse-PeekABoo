import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms/core/theme/app_theme.dart';
import 'package:wms/core/di/dependency_injection.dart';
import 'package:wms/core/routes/app_router.dart';
import 'package:wms/core/widgets/layout/admin_app_bar.dart';
import 'package:wms/features/supervisor/presentation/cubits/dashboard_cubit.dart';
import 'package:wms/features/supervisor/data/repositories/ai_review_repository.dart';
import 'package:wms/features/supervisor/data/repositories/flag_repository.dart';
import 'package:wms/features/admin/data/repositories/admin_repository.dart';

// Imports for specific pages
import 'package:wms/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:wms/features/admin/presentation/pages/access_logs.dart';
import 'package:wms/features/admin/presentation/pages/ai_performance_screen.dart';
import 'package:wms/features/admin/presentation/pages/export_reports_screen.dart';
import 'package:wms/features/admin/presentation/pages/create_new_user_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final bool isView;
  const AdminDashboardScreen({super.key, this.isView = false});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    Connectivity().onConnectivityChanged.listen((_) => _checkConnectivity());
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    final online = results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);
    if (mounted && _isOnline != online) setState(() => _isOnline = online);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SupervisorDashboardCubit(sl<AiReviewRepository>(), sl<FlagRepository>())..loadDashboard(),
      child: Scaffold(
        backgroundColor: AppTheme.veryLightGrey,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(12.0),
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
              child: const CircleAvatar(
                backgroundColor: Color(0xFFF5F5F5),
                child: Icon(Icons.person_outline, color: Color(0xFF5D6266)),
              ),
            ),
          ),
          centerTitle: true,
          title: Image.asset('assets/images/logo.png', height: 30),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Color(0xFF5D6266)),
              onPressed: () => Navigator.pushNamed(context, '/admin/settings'),
            ),
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Color(0xFF5D6266)),
              onPressed: () {}, // Notifications
            ),
          ],
        ),
        body: Column(
          children: [
            if (!_isOnline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: Colors.amber.shade100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off, size: 18, color: Colors.amber.shade900),
                    const SizedBox(width: 8),
                    Text(
                      'Hors ligne — synchronisation au retour de la connexion',
                      style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: BlocBuilder<SupervisorDashboardCubit, SupervisorDashboardState>(
                builder: (context, state) {
                  if (state is SupervisorDashboardLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is SupervisorDashboardError) {
                    return Center(
                      child: Text(
                        'Erreur: ${state.message}',
                        style: GoogleFonts.lato(color: AppTheme.red),
                      ),
                    );
                  } else if (state is SupervisorDashboardLoaded) {
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Bannière de bienvenue
                          Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/admin.png',
                        width: double.infinity,
                        height: 170,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: double.infinity,
                          height: 170,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported),
                        ),
                      ),
                    ),
                  ),

                  // Actions rapides
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Actions rapides',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, AppRouter.adminWarehouseConfig);
                          },
                          child: _buildQuickActionButton(
                            icon: Icons.warehouse_outlined,
                            label: 'Configuration de l\'entrepôt',
                            color: AppTheme.lightBlue,
                            width: MediaQuery.of(context).size.width * 0.9,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                             Navigator.pushNamed(context, AppRouter.adminCreateUser);
                          },
                          child: _buildQuickActionButton(
                            icon: Icons.person_add_outlined,
                            label: 'Créer un utilisateur',
                            color: const Color(0xFFFDB913),
                            width: MediaQuery.of(context).size.width * 0.9,
                          ),
                        ),

                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AccessLogsScreen(),
                                    ),
                                  );
                                },
                                child: _buildQuickActionButton(
                                  icon: Icons.description_outlined,
                                  label: 'Historique d\'accès',
                                  color: const Color(0xFF4A9B9F),
                                  width: MediaQuery.of(context).size.width * 0.4,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ExportReportsScreen(),
                                    ),
                                  );
                                },
                                child: _buildQuickActionButton(
                                  icon: Icons.download_outlined,
                                  label: 'Exporter',
                                  color: const Color(0xFF4A9B9F),
                                  width: MediaQuery.of(context).size.width * 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Statistiques réelles (entrepôts, utilisateurs)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Statistiques',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FutureBuilder<Map<String, int>>(
                      future: () async {
                        try {
                          final admin = sl<AdminRepository>();
                          final warehouses = await admin.getWarehouses();
                          final users = await admin.getUsers();
                          return {'warehouses': warehouses.length, 'users': users.length};
                        } catch (_) {
                          return {'warehouses': 0, 'users': 0};
                        }
                      }(),
                      builder: (context, snap) {
                        final w = snap.data?['warehouses'] ?? 0;
                        final u = snap.data?['users'] ?? 0;
                        return Row(
                          children: [
                            Expanded(
                              child: _buildStatTile(Icons.warehouse_outlined, 'Entrepôts', '$w'),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatTile(Icons.people_outline, 'Utilisateurs', '$u'),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Santé du système
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Santé du système',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        children: [
                          _buildHealthMetric(
                            icon: Icons.check_circle_outline,
                            label: 'Statut du système',
                            value: 'Tous les systèmes en ligne',
                            color: const Color(0xFF4A9B9F),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Serveur',
                                      style: GoogleFonts.lato(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'En ligne',
                                      style: GoogleFonts.lato(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF27AE60),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Dernière synchro',
                                      style: GoogleFonts.lato(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Il y a 2 min',
                                      style: GoogleFonts.lato(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Base de données',
                                      style: GoogleFonts.lato(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Saine',
                                      style: GoogleFonts.lato(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF27AE60),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Disponibilité',
                                      style: GoogleFonts.lato(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '99.8%',
                                      style: GoogleFonts.lato(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildAlertCard(
                                  icon: Icons.warning_amber_outlined,
                                  label: 'Alertes critiques',
                                  sublabel: 'Nécessite attention',
                                  color: const Color(0xFFFDB913),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildAlertCard(
                                  icon: Icons.flag_outlined,
                                  label: 'Tous les drapeaux',
                                  sublabel: 'Résolution en attente',
                                  color: const Color(0xFFE74C3C),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Performances IA
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Performances IA',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AIPerformanceScreen(),
                          ),
                        );
                      },
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
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4A9B9F).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.analytics_outlined,
                                    color: Color(0xFF4A9B9F),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Performances IA',
                                    style: GoogleFonts.lato(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.grey[400],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildPerformanceStat('94%', 'Prévisions'),
                                _buildPerformanceStat('87%', 'Optimisation'),
                                _buildPerformanceStat('18', 'Remplacements'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Aperçu des opérations
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Aperçu des opérations',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildOperationCard(
                                  icon: Icons.receipt_long_outlined,
                                  label: 'Réception',
                                  count: '24',
                                  percentage: 95,
                                  color: AppTheme.lightBlue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildOperationCard(
                                  icon: Icons.storage_outlined,
                                  label: 'Stockage',
                                  count: '18',
                                  percentage: 88,
                                  color: AppTheme.yellow,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildOperationCard(
                                  icon: Icons.shopping_cart_outlined,
                                  label: 'Préparation',
                                  count: '32',
                                  percentage: 96,
                                  color: AppTheme.darkBlue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildOperationCard(
                                  icon: Icons.local_shipping_outlined,
                                  label: 'Livraison',
                                  count: '15',
                                  percentage: 97,
                                  color: AppTheme.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Activité utilisateur
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Activité utilisateur',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
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
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.supervised_user_circle_outlined,
                                      color: AppTheme.darkBlue,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Utilisateurs actifs',
                                      style: GoogleFonts.lato(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.grey[400],
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildUserCountCard('48', 'Employés'),
                                _buildUserCountCard('12', 'Superviseurs'),
                                _buildUserCountCard('3', 'Admins'),
                              ],
                            ),
                          ),
                          Divider(color: Colors.grey[200], height: 1),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Activité récente (5 derniers)',
                                  style: GoogleFonts.lato(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildActivityItem(
                                  'Jean a terminé une tâche de Réception',
                                  '3m',
                                ),
                                const SizedBox(height: 10),
                                _buildActivityItem(
                                  'Sarah a commencé une tâche de Stockage',
                                  '1h',
                                ),
                                const SizedBox(height: 10),
                                _buildActivityItem(
                                  'Mike a signalé un problème d\'emplacement',
                                  '8h',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Utilisation de l'entrepôt
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Utilisation de l\'entrepôt',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
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
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.assessment_outlined,
                                      color: AppTheme.lightBlue,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Aperçu des capacités',
                                      style: GoogleFonts.lato(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.grey[400],
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                          Divider(color: Colors.grey[200], height: 1),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Capacité de stockage',
                                      style: GoogleFonts.lato(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      '87%',
                                      style: GoogleFonts.lato(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: 0.87,
                                    minHeight: 6,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      AppTheme.lightBlue,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Chariots actifs',
                                          style: GoogleFonts.lato(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '24/32',
                                          style: GoogleFonts.lato(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Zones occupées',
                                          style: GoogleFonts.lato(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '234/456',
                                          style: GoogleFonts.lato(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      )),
    ],
  ),
    ),
    );
  }

  Widget _buildStatTile(IconData icon, String label, String count) {
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
          Icon(icon, color: AppTheme.lightBlue, size: 24),
          const SizedBox(height: 8),
          Text(
            count,
            style: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          Text(
            label,
            style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
      ],
    );
  }

  Widget _buildAlertCard({
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(fontSize: 9, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceStat(String value, String label) {
    return Column(
      children: [
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
          style: GoogleFonts.lato(fontSize: 11, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildOperationCard({
    required IconData icon,
    required String label,
    required String count,
    required int percentage,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: GoogleFonts.lato(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$percentage% terminée',
            style: GoogleFonts.lato(fontSize: 10, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCountCard(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: GoogleFonts.lato(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.darkBlue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.lato(fontSize: 10, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildActivityItem(String activity, String time) {
    return Row(
      children: [
        Icon(Icons.circle, color: AppTheme.lightBlue, size: 8),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            activity,
            style: GoogleFonts.lato(fontSize: 11, color: Colors.black87),
          ),
        ),
        Text(
          time,
          style: GoogleFonts.lato(fontSize: 10, color: Colors.grey[500]),
        ),
      ],
    );
  }
}