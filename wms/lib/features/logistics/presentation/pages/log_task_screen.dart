import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/core/routes/app_router.dart';
import 'package:wms/core/theme/app_theme.dart';
import 'package:wms/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:wms/features/logistics/presentation/cubits/employee_task_cubit.dart';
import 'package:wms/features/logistics/data/models/task_model.dart';
import 'package:wms/core/widgets/layout/modern_floating_navbar.dart';
import 'package:wms/features/logistics/presentation/pages/employee_all_tasks_screen.dart';
import 'package:wms/features/inventory/presentation/pages/employee_dashboard_screen.dart';
import 'package:wms/features/inventory/presentation/pages/employee_main_screen.dart';

class LogTaskScreen extends StatefulWidget {
  const LogTaskScreen({super.key});

  @override
  State<LogTaskScreen> createState() => _LogTaskScreenState();
}

class _LogTaskScreenState extends State<LogTaskScreen> {
  int _currentIndex = 1;

  final List<Widget> _pages = [
    const EmployeeDashboardScreen(),
    const SizedBox(), // Placeholder for Log
    const EmployeeAllTasksScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const EmployeeMainScreen()),
      );
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  String? _selectedType;
  TaskModel? _selectedTask;
  final TextEditingController _notesController = TextEditingController();

  final List<Map<String, dynamic>> _taskTypes = [
    {'name': 'Receipt', 'icon': Icons.inventory_2_outlined},
    {'name': 'Storage', 'icon': Icons.warehouse_outlined},
    {'name': 'Picking', 'icon': Icons.shopping_cart_outlined},
    {'name': 'Delivery', 'icon': Icons.local_shipping_outlined},
  ];

  void _submitLog() async {
    if (_selectedType == null || _selectedTask == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select task type and specific task'),
        ),
      );
      return;
    }

    final authCubit = context.read<AuthCubit>();

    // Log action to backend
    await authCubit.logUserAction(
      action: 'SUBMIT_LOG',
      entityType: 'TASK',
      entityId: _selectedTask!.id,
      payload: {
        'task_type': _selectedType,
        'task_title': _selectedTask!.title,
        'notes': _notesController.text,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task log submitted successfully!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
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
            onPressed: () =>
                Navigator.pushNamed(context, '/employee/notifications'),
          ),
        ],
      ),
      bottomNavigationBar: ModernFloatingNavbar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
      body: BlocBuilder<EmployeeTaskCubit, EmployeeTaskState>(
        builder: (context, state) {
          final tasks = state is EmployeeTaskLoaded
              ? state.tasks
              : <TaskModel>[];
          final filteredTasks = tasks
              .where(
                (t) =>
                    t.type.name.toLowerCase() == _selectedType?.toLowerCase(),
              )
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Task Type',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: _taskTypes.length,
                  itemBuilder: (context, index) {
                    final type = _taskTypes[index];
                    final isSelected = _selectedType == type['name'];
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedType = type['name'];
                        _selectedTask = null;
                      }),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ?  AppTheme.lightBlue
                                : Colors.grey.shade200,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              type['icon'],
                              color: isSelected
                                  ?  AppTheme.lightBlue
                                  : Colors.grey[400],
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              type['name'],
                              style: GoogleFonts.lato(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ?  AppTheme.lightBlue
                                    : Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                if (_selectedType != null) ...[
                  const SizedBox(height: 32),
                  Text(
                    'Select Specific Task',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (filteredTasks.isEmpty)
                    Center(
                      child: Text(
                        'No $_selectedType tasks available',
                        style: GoogleFonts.lato(color: Colors.grey),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredTasks.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final task = filteredTasks[index];
                        final isSelected = _selectedTask?.id == task.id;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedTask = task),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.lightBlue
                                    : Colors.grey.shade100,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF00796B,
                                    ).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.inventory_2_outlined,
                                    color: AppTheme.lightBlue,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        task.title,
                                        style: GoogleFonts.lato(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        task.products.isNotEmpty
                                            ? task.products.first.name
                                            : 'No products',
                                        style: GoogleFonts.lato(
                                          color: Colors.grey[600],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: AppTheme.lightBlue,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
                if (_selectedTask != null) ...[
                  const SizedBox(height: 32),
                  Text(
                    'Notes (Optional)',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Add any notes about the task completion...',
                      hintStyle: GoogleFonts.lato(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _submitLog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:  AppTheme.lightBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Submit Log',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
