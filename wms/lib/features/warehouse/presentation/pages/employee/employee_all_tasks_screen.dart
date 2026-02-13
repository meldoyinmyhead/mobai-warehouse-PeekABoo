import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms/core/theme/app_theme.dart';
import 'package:wms/features/warehouse/data/models/task_model.dart';
import 'package:wms/features/warehouse/presentation/cubits/employee/employee_task_cubit.dart';

class EmployeeAllTasksScreen extends StatefulWidget {
  const EmployeeAllTasksScreen({super.key});

  @override
  State<EmployeeAllTasksScreen> createState() => _EmployeeAllTasksScreenState();
}

class _EmployeeAllTasksScreenState extends State<EmployeeAllTasksScreen> {
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
                  final tasks = state.filter == 'All'
                      ? state.tasks
                      : state.tasks
                          .where((t) =>
                              t.title.contains(state.filter) ||
                              t.type.toString().contains(state.filter))
                          .toList();

                  if (tasks.isEmpty) {
                    return Center(
                      child: Text(
                        "Aucune tâche trouvée",
                        style: TextStyle(color: Colors.grey[600]),
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
    String taskType = 'Réception';

    if (task.title.contains('Receipt')) {
      iconColor = AppTheme.lightBlue;
      icon = Icons.inventory_2;
      taskType = 'Réception';
    } else if (task.title.contains('Storage')) {
      iconColor = AppTheme.green;
      icon = Icons.warehouse_outlined;
      taskType = 'Stockage';
    } else if (task.title.contains('Picking')) {
      iconColor = AppTheme.lightBlue;
      icon = Icons.shopping_cart_outlined;
      taskType = 'Préparation';
    } else if (task.title.contains('Delivery')) {
      iconColor = AppTheme.darkBlue;
      icon = Icons.local_shipping_outlined;
      taskType = 'Livraison';
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
                              taskType,
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
                        'Téléphones mobiles Samsung',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            'Porte A',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Commande: ${task.id}',
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
                      backgroundColor: AppTheme.lightBlue,
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
                      foregroundColor: AppTheme.lightBlue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppTheme.lightBlue),
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