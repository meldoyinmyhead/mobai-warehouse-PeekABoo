import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/core/widgets/supervisorBottonBar.dart';
import 'package:wms/core/routes/app_router.dart';
import 'package:wms/features/warehouse/presentation/cubits/supervisor/dashboard_cubit.dart';
import 'package:wms/features/warehouse/data/repositories/task_repository.dart';
import 'package:wms/core/theme/app_theme.dart';
import 'package:wms/features/warehouse/presentation/pages/supervisor/supervisor_notifications_screen.dart';
import 'package:wms/features/warehouse/presentation/pages/supervisor/supervisor_settings_screen.dart';
import 'package:wms/features/warehouse/presentation/pages/supervisor/supervisor_profile_screen.dart';

class SupervisorDashboardScreen extends StatefulWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  State<SupervisorDashboardScreen> createState() =>
      _SupervisorDashboardScreenState();
}

class _SupervisorDashboardScreenState extends State<SupervisorDashboardScreen> {
  int _currentIndex = 0;

  void _onNavBarTap(int index) {
    if (index == _currentIndex)
      return; // Don't navigate if already on this page

    setState(() {
      _currentIndex = index;
    });

    // Handle navigation based on index
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, AppRouter.supervisorDashboard);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, AppRouter.supervisorMap);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, AppRouter.supervisorAiReview);
        break;
      case 3:
        Navigator.pushReplacementNamed(context, AppRouter.supervisorFlagged);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return BlocProvider(
      create: (context) =>
          SupervisorDashboardCubit(TaskRepository())..loadDashboard(),
      child: Scaffold(
        backgroundColor: AppTheme.veryLightGrey,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: Padding(
          padding: const EdgeInsets.all(12.0),
          child: GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRouter.supervisorProfile),
            child: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person_outline, color: Color(0xFF5D6266)),
            ),
          ),
        ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [Image.asset('assets/images/logo.png', height: 30)],
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.settings_outlined,
                color: Color(0xFF5D6266),
              ),
              onPressed: () {
                Navigator.pushNamed(context, AppRouter.supervisorSettings);
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Color(0xFF5D6266),
              ),
              onPressed: () {
                Navigator.pushNamed(context, AppRouter.supervisorNotifications);
              },
            ),
          ],
        ),
        body: BlocBuilder<SupervisorDashboardCubit, SupervisorDashboardState>(
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
                    // Welcome Card
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.darkBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bon retour,',
                                  style: GoogleFonts.lato(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  'Mobina!',
                                  style: GoogleFonts.lato(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Jeudi,',
                                  style: GoogleFonts.lato(
                                    fontSize: 11,
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  '12 Février 2026',
                                  style: GoogleFonts.lato(
                                    fontSize: 11,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.wifi,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'En ligne',
                                        style: GoogleFonts.lato(
                                          fontSize: 11,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Image.asset(
                            'assets/images/super.png',
                            width: screenWidth * 0.3,
                            height: screenWidth * 0.3,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: screenWidth * 0.3,
                                height: screenWidth * 0.3,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.assessment,
                                  size: 50,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // Alerts Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Alertes',
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
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildAlertCard(
                              icon: Icons.flag_outlined,
                              count: '5',
                              label: 'Tâches signalées',
                              color: AppTheme.yellow,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildAlertCard(
                              icon: Icons.star_outline,
                              count: '5',
                              label: 'IA Nouveau',
                              color: AppTheme.yellow,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.red.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.red.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.error_outline,
                                color: AppTheme.red,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Opérations urgentes',
                                style: GoogleFonts.lato(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatCard('3', 'Retards de livraison'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              '2',
                              'Préparation nécessaire',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Operations Overview
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
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildOperationCard(
                                  icon: 'assets/icons/receipt.png',
                                  count: '5',
                                  total: '10',
                                  label: 'Réception',
                                  progress: 0.5,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildOperationCard(
                                  icon: 'assets/icons/storage.png',
                                  count: '8',
                                  total: '15',
                                  label: 'Stockage',
                                  progress: 0.53,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildOperationCard(
                                  icon: 'assets/icons/chariot.png',
                                  count: '12',
                                  total: '20',
                                  label: 'Préparation',
                                  progress: 0.6,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildOperationCard(
                                  icon: 'assets/icons/delivery.png',
                                  count: '3',
                                  total: '8',
                                  label: 'Livraison',
                                  progress: 0.375,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Team Status
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Statut de l\'équipe',
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
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildTeamCard('12', 'Employés actifs'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTeamCard('12', 'Quarts complets'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        bottomNavigationBar: SupervisorBottomBar(
          currentIndex: _currentIndex,
          onTap: _onNavBarTap,
        ),
      ),
    );
  }

  Widget _buildAlertCard({
    required IconData icon,
    required String count,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.grey[600], size: 20),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Text(
                  count,
                  style: GoogleFonts.lato(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: GoogleFonts.lato(fontSize: 11, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String count, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            count,
            style: GoogleFonts.lato(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.lato(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationCard({
    required String icon,
    required String count,
    required String total,
    required String label,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(icon, width: 20, height: 20),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              count,
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: GoogleFonts.lato(fontSize: 11, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.lightBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCard(String count, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            color: AppTheme.lightBlue,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
