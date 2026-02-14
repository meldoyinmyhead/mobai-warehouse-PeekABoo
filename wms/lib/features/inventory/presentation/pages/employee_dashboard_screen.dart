import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms/core/theme/app_theme.dart';
import 'package:wms/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:wms/features/logistics/data/models/task_model.dart';
import 'package:wms/features/logistics/presentation/cubits/employee_task_cubit.dart';
import 'package:wms/core/di/dependency_injection.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  State<EmployeeDashboardScreen> createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  bool _isOnline = true;
  bool _tasksLoaded = false;

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
    final authState = context.watch<AuthCubit>().state;
    if (!_tasksLoaded && authState is Authenticated) {
      _tasksLoaded = true;
      context.read<EmployeeTaskCubit>().loadTasks(authState.user.id);
    }
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppTheme.lightGrey,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(12.0),
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/employee/profile'),
            child: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person_outline, color: Color(0xFF5D6266)),
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Image.asset('assets/images/logo.png', height: 30)],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF5D6266)),
            onPressed: () => Navigator.pushNamed(context, '/employee/settings'),
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF5D6266),
            ),
            onPressed: () => Navigator.pushNamed(context, '/employee/notifications'),
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
                    'Hors ligne — les changements seront synchronisés au retour de la connexion',
                    style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(0),
                  topRight: Radius.circular(0),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(screenWidth, _isOnline),
                    const SizedBox(height: 24),
                    const Text(
                      "Tâches d'aujourd'hui",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    BlocBuilder<EmployeeTaskCubit, EmployeeTaskState>(
                      builder: (context, state) {
                        int receipt = 0, storage = 0, picking = 0, delivery = 0, total = 0, completed = 0;
                        if (state is EmployeeTaskLoaded) {
                          final tasks = state.tasks;
                          receipt = tasks.where((t) => t.type == TaskType.receipt).length;
                          storage = tasks.where((t) => t.type == TaskType.storage).length;
                          picking = tasks.where((t) => t.type == TaskType.picking).length;
                          delivery = tasks.where((t) => t.type == TaskType.delivery).length;
                          total = tasks.length;
                          completed = tasks.where((t) => t.status == TaskStatus.completed).length;
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTaskGrid(receipt, storage, picking, delivery),
                            const SizedBox(height: 24),
                            _buildProgressCard(completed, total),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Activités récentes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildActivityList(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      
    );
  }

  Widget _buildWelcomeCard(double screenWidth, bool isOnline) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFEFE),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bon retour,',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const Text(
                      'Mobina!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Jeudi,',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const Text(
                      '12 Février 2026',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Image.asset(
                'assets/images/cuate.png',
                width: screenWidth * 0.35,
                height: screenWidth * 0.35,
                fit: BoxFit.contain,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.wifi,
                color: isOnline ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isOnline ? 'En ligne' : 'Hors ligne',
                style: TextStyle(
                  fontSize: 14,
                  color: isOnline ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskGrid(int receipt, int storage, int picking, int delivery) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard('$receipt', 'Réception', 'assets/icons/receipt.png'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard('$storage', 'Stockage', 'assets/icons/storage.png'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard('$picking', 'Préparation', 'assets/icons/chariot.png'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard('$delivery', 'Livraison', 'assets/icons/delivery.png'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String count, String label, String icon) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Image.asset(
            icon,
            width: 32,
            height: 32,
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(int completed, int total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Progrès d'aujourd'hui",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tâches à faire / terminées',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            Text(
              '$completed / $total',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: total > 0 ? completed / total : 0.0,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.darkBlue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityList() {
    return Column(
      children: [
        _buildActivityItem('Vous avez vérifié 12 colis', Icons.check_circle, const Color(0xFFFDD835)),
        const SizedBox(height: 8),
        _buildActivityItem('Échec de l\'enregistrement', Icons.cancel, const Color(0xFFE57373), subtitle: 'pour allocation'),
         const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildActivityItem(String title, IconData icon, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[400]),
        ],
      ),
    );
  }
}