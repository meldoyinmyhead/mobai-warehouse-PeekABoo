import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms/features/warehouse/data/models/task_model.dart';
import 'package:wms/features/warehouse/presentation/cubits/employee/employee_task_cubit.dart';
import 'package:wms/features/warehouse/data/repositories/task_repository.dart';
import 'package:wms/core/di/dependency_injection.dart';

class EmployeeDashboardScreen extends StatelessWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/employee/profile'),
              child: const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white)),
          ),
        ),
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              Text('BBMS', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 20)),
              Text(' ELECTRIC', style: TextStyle(color: Colors.orange, fontSize: 14)), 
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.settings_outlined, color: Colors.grey), onPressed: () => Navigator.pushNamed(context, '/employee/settings')),
          IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.grey), onPressed: () => Navigator.pushNamed(context, '/employee/notifications')),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 24),
            const Text("Today's Tasks", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildTaskGrid(),
            const SizedBox(height: 24),
            _buildProgressCard(),
            const SizedBox(height: 24),
            const Text("Recent Activities", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildActivityList(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 5)),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          const Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Welcome back,", style: TextStyle(fontSize: 16, color: Colors.black87)),
                Text("Mobina!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal)),
                SizedBox(height: 8),
                Text("Thursday,\nFebruary 12, 2026", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Image.network('https://via.placeholder.com/100', height: 100), // Placeholder for illustration
          )
        ],
      ),
    );
  }

  Widget _buildTaskGrid() {
    // Mock counts based on screenshot
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1, // Changed from 1.3 to giving more height
      children: [
        _buildStatCard('5', 'Receipt', Icons.inventory_2, Colors.lightBlue),
        _buildStatCard('8', 'Storage', Icons.garage, Colors.orange), // garage as closest to storage
        _buildStatCard('12', 'Picking', Icons.shopping_cart, Colors.teal),
        _buildStatCard('3', 'Delivery', Icons.local_shipping, Colors.purple),
      ],
    );
  }

  Widget _buildStatCard(String count, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(count, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
               Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
             ],
          )
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Today's Progress", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Completed Tasks", style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text("18/28", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: 18/28,
            backgroundColor: Colors.grey[200],
            color: Colors.teal[800], // Dark teal
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          )
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    return Column(
      children: [
        _buildActivityItem('You have checked 12 packages', Icons.check_box_outline_blank, Colors.yellow),
        const SizedBox(height: 12),
        _buildActivityItem('Failure to register', Icons.error_outline, Colors.red, subtitle: 'the description'),
      ],
    );
  }

  Widget _buildActivityItem(String title, IconData icon, Color color, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
       decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
           Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (subtitle != null)
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}
