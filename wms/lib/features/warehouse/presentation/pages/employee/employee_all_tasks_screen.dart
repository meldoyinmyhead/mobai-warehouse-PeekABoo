import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms/features/warehouse/data/models/task_model.dart';
import 'package:wms/features/warehouse/presentation/cubits/employee/employee_task_cubit.dart';

class EmployeeAllTasksScreen extends StatefulWidget {
  const EmployeeAllTasksScreen({super.key});

  @override
  State<EmployeeAllTasksScreen> createState() => _EmployeeAllTasksScreenState();
}

class _EmployeeAllTasksScreenState extends State<EmployeeAllTasksScreen> {
  // Mock data for filter chips based on screenshot
  final List<String> _filters = ['All', 'Receipt', 'Storage', 'Picking', 'Delivery'];
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light grey background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white)),
             SizedBox(width: 10),
            Text('BBMS', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 20)),
             Text(' ELECTRIC', style: TextStyle(color: Colors.orange, fontSize: 14)), // Assuming logo text structure
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.settings_outlined, color: Colors.grey), onPressed: () => Navigator.pushNamed(context, '/employee/settings')), // Route to settings
          IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.grey), onPressed: () => Navigator.pushNamed(context, '/employee/notifications')), // Route to notifications
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your Tasks', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal)),
                   const Text('Manage your warehouse operations', style: TextStyle(color: Colors.grey)),
                   const SizedBox(height: 16),
                   // Search Bar
                    TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        hintText: 'Search tasks or order numbers...',
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
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
                                context.read<EmployeeTaskCubit>().filterTasks(filter);
                              },
                              selectedColor: Colors.teal,
                              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black54),
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300)),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<EmployeeTaskCubit, EmployeeTaskState>(
                builder: (context, state) {
                  if (state is EmployeeTaskLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is EmployeeTaskLoaded) {
                    final tasks = state.filter == 'All'
                        ? state.tasks
                        : state.tasks.where((t) => t.title.contains(state.filter) || t.type.toString().contains(state.filter)).toList();

                    if (tasks.isEmpty) return const Center(child: Text("No tasks found"));

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                         return _buildTaskCard(context, tasks[index]);
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            )
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, TaskModel task) {
    Color iconColor = Colors.teal;
    IconData icon = Icons.inventory_2;

     if (task.title.contains('Receipt')) { iconColor = Colors.lightBlue; icon = Icons.inventory_2; } // Box
    else if (task.title.contains('Storage')) { iconColor = Colors.orange; icon = Icons.garage; } // Warehouse
    else if (task.title.contains('Picking')) { iconColor = Colors.teal; icon = Icons.shopping_cart; } // Cart
    else if (task.title.contains('Delivery')) { iconColor = Colors.purple; icon = Icons.local_shipping; } // Truck


    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
             Row(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Container(
                   padding: const EdgeInsets.all(12),
                   decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                   child: Icon(icon, color: iconColor),
                 ),
                 const SizedBox(width: 16),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             // Chips: Type and Status (Mocked for now)
                             Container(
                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                               decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                               child: Text(task.title.split(' ').first, style: TextStyle(color: iconColor, fontSize: 10, fontWeight: FontWeight.bold)), // e.g., Receipt
                             ),
                             if (task.status == TaskStatus.pending)
                                const Icon(Icons.circle, color: Colors.orange, size: 8)
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Samsung Mobile Phones' /* Placeholder for task.title or connected product */, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        const Text('Gate A', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('Order: ${task.id}', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                     ],
                   ),
                 )
               ],
             ),
             const SizedBox(height: 16),
             Row(
               children: [
                 Expanded(
                   child: ElevatedButton(
                     onPressed: () {
                        Navigator.pushNamed(context, '/employee/task_detail', arguments: task);
                     },
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.teal[800],
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                     ),
                     child: const Text('View Details'),
                   ),
                 ),
                 const SizedBox(width: 16),
                 Expanded(
                   child: OutlinedButton(
                     onPressed: () {
                       // Log Directly
                     },
                     style: OutlinedButton.styleFrom(
                       foregroundColor: Colors.teal[800],
                       side: BorderSide(color: Colors.teal[800]!),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                     ),
                     child: const Text('Log Directly'),
                   ),
                 ),
               ],
             )
          ],
        ),
      ),
    );
  }
}
