import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms/core/theme/app_theme.dart';
import 'package:wms/features/logistics/data/models/task_model.dart';
import 'package:wms/features/logistics/presentation/cubits/employee_task_cubit.dart';
import 'package:wms/features/auth/presentation/cubits/auth_cubit.dart';

class EmployeeAllTasksScreen extends StatefulWidget {
  const EmployeeAllTasksScreen({super.key});

  @override
  State<EmployeeAllTasksScreen> createState() => _EmployeeAllTasksScreenState();
}

class _EmployeeAllTasksScreenState extends State<EmployeeAllTasksScreen> {
  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() {
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      context.read<EmployeeTaskCubit>().loadTasks(authState.user.id);
    }
  }

  final List<String> _filters = [
    'Tout',
    'Réception',
    'Stockage',
    'Préparation',
    'Livraison',
  ];
  String _getEnglishFilter(String frenchFilter) {
  switch (frenchFilter) {
    case 'Tout':
      return 'All';
    case 'Réception':
      return 'Receipt';
    case 'Stockage':
      return 'Storage';
    case 'Préparation':
      return 'Picking';
    case 'Livraison':
      return 'Delivery';
    default:
      return 'All';
  }
}
  String _selectedFilter = 'Tout';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(12.0),
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/employee/profile'),
            child: CircleAvatar(
              backgroundColor: Colors.grey[200],
              child: const Icon(Icons.person_outline, color: Color(0xFF5D6266)),
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Image.asset('assets/images/logo.png', height: 30)],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF5D6266)),
            onPressed: _loadTasks,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF5D6266)),
            onPressed: () => Navigator.pushNamed(context, '/employee/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Color(0xFF5D6266)),
            onPressed: () => Navigator.pushNamed(context, '/employee/notifications'),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Container(
            color: AppTheme.veryLightGrey,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          Text(
                            'Vos tâches',
                            style: TextStyle(
                              fontSize: screenWidth * 0.06,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.lightBlue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Gérez vos opérations d\'entrepôt',
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                    Image.asset(
                      'assets/images/tasks.png',
                      height: screenWidth * 0.25,
                      width: screenWidth * 0.25,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search Bar
               TextField(
  decoration: InputDecoration(
    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
    hintText: 'Rechercher des tâches ou numéros de commande...',
    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(25),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(25),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(25),
      borderSide: BorderSide(color: AppTheme.lightBlue, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
  ),
),

                const SizedBox(height: 16),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                           context.read<EmployeeTaskCubit>().filterTasks(_getEnglishFilter(filter));
                          },
                          selectedColor: AppTheme.lightBlue,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? Colors.transparent : Colors.grey.shade300,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          // Tasks List
          Expanded(
            child: BlocBuilder<EmployeeTaskCubit, EmployeeTaskState>(
              builder: (context, state) {
                if (state is EmployeeTaskLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is EmployeeTaskLoaded) {
                  final tasks = context.read<EmployeeTaskCubit>().filteredTasks;

                  if (tasks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            "Aucune tâche trouvée",
                            style: TextStyle(color: Colors.grey[600], fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Essayez de changer le filtre",
                            style: TextStyle(color: Colors.grey[400], fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      return _buildTaskCard(context, tasks[index], screenWidth);
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
     
    );
  }

  Widget _buildTaskCard(BuildContext context, TaskModel task, double screenWidth) {
    Color iconColor = AppTheme.lightBlue;
    IconData icon = Icons.inventory_2;
    String taskTypeLabel = 'Général';

    switch (task.type) {
      case TaskType.receipt:
        iconColor = AppTheme.lightBlue;
        icon = Icons.inventory_2;
        taskTypeLabel = 'Réception';
        break;
      case TaskType.storage:
        iconColor = AppTheme.green;
        icon = Icons.warehouse_outlined;
        taskTypeLabel = 'Stockage';
        break;
      case TaskType.picking:
        iconColor = AppTheme.lightBlue;
        icon = Icons.shopping_cart_outlined;
        taskTypeLabel = 'Préparation';
        break;
      case TaskType.delivery:
        iconColor = AppTheme.darkBlue;
        icon = Icons.local_shipping_outlined;
        taskTypeLabel = 'Livraison';
        break;
      default:
        iconColor = Colors.grey;
        icon = Icons.task_outlined;
        taskTypeLabel = 'Tâche';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: iconColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              taskTypeLabel,
                              style: TextStyle(
                                color: iconColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (task.status == TaskStatus.pending)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.yellow.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.circle,
                                color: AppTheme.yellow,
                                size: 8,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        task.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.description_outlined, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              task.description,
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${task.id.split('-').first}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
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
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/employee/task_detail',
                        arguments: task,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: iconColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Voir détails',
                      style: TextStyle(fontSize: 13, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Log Directly
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: iconColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: iconColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Enregistrer',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}