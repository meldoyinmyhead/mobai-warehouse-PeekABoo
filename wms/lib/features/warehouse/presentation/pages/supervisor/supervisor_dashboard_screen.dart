import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms/features/warehouse/presentation/cubits/supervisor/dashboard_cubit.dart';
import 'package:wms/features/warehouse/data/repositories/task_repository.dart';

class SupervisorDashboardScreen extends StatelessWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SupervisorDashboardCubit(TaskRepository())..loadDashboard(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Supervisor Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
               // In a real app we would use context.read, but here we need a builder or consumer
              onPressed: () {}, 
            )
          ],
        ),
        body: BlocBuilder<SupervisorDashboardCubit, SupervisorDashboardState>(
          builder: (context, state) {
            if (state is SupervisorDashboardLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is SupervisorDashboardError) {
              return Center(child: Text('Error: ${state.message}'));
            } else if (state is SupervisorDashboardLoaded) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Pending Validations', state.pendingValidations.length),
                    _buildTaskList(state.pendingValidations),
                    const SizedBox(height: 20),
                    _buildSectionHeader('Flagged Issues 🚩', state.flaggedTasks.length),
                    _buildTaskList(state.flaggedTasks, isFlagged: true),
                    const SizedBox(height: 20),
                    _buildSectionHeader('AI Recommendations 🤖', state.aiRecommendations.length),
                    _buildTaskList(state.aiRecommendations, isAi: true),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<dynamic> tasks, {bool isFlagged = false, bool isAi = false}) {
    if (tasks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('No items in this category.'),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: isFlagged
              ? RoundedRectangleBorder(side: const BorderSide(color: Colors.red, width: 2), borderRadius: BorderRadius.circular(8))
              : null,
          child: ListTile(
            leading: Icon(
              isFlagged ? Icons.warning : (isAi ? Icons.smart_toy : Icons.task),
              color: isFlagged ? Colors.red : Colors.blue,
            ),
            title: Text(task.title ?? 'Task #$index'), // Assuming title exists
            subtitle: Text(task.description ?? 'Description...'),
            trailing: isAi
                ? ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/supervisor/ai_review'),
                    child: const Text('Review'),
                  )
                : const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              if (isAi) {
                Navigator.pushNamed(context, '/supervisor/ai_review');
              }
            },
          ),
        );
      },
    );
  }
}
