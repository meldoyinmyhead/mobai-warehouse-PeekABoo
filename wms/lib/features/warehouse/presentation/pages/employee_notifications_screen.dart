import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms/features/warehouse/presentation/cubits/employee/employee_notification_cubit.dart';

class EmployeeNotificationsScreen extends StatefulWidget {
  const EmployeeNotificationsScreen({super.key});

  @override
  State<EmployeeNotificationsScreen> createState() => _EmployeeNotificationsScreenState();
}

class _EmployeeNotificationsScreenState extends State<EmployeeNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<EmployeeNotificationCubit>().loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Latest notifications'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
         leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
           // Header Banner
           Container(
             width: double.infinity,
             padding: const EdgeInsets.all(24),
             color: Colors.teal[700],
             child: const Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text('Notifications', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                 SizedBox(height: 8),
                 Text('You have 2 unread notifications', style: TextStyle(color: Colors.white70)),
               ],
             ),
           ),
           Expanded(
             child: BlocBuilder<EmployeeNotificationCubit, EmployeeNotificationState>(
               builder: (context, state) {
                 if (state is EmployeeNotificationLoading) {
                   return const Center(child: CircularProgressIndicator());
                 } else if (state is EmployeeNotificationLoaded) {
                   return ListView.builder(
                     padding: const EdgeInsets.all(16),
                     itemCount: state.notifications.length,
                     itemBuilder: (context, index) {
                       final notification = state.notifications[index];
                       return _buildNotificationCard(notification);
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

  Widget _buildNotificationCard(NotificationModel notification) {
    Color iconColor;
    Color bgColor;
    IconData icon;

    switch (notification.type) {
      case 'success':
        iconColor = Colors.orange; // Yellowish orange as per screenshot
        bgColor = Colors.yellow[50]!;
        icon = Icons.check_circle_outline;
        break;
      case 'info':
        iconColor = Colors.teal;
        bgColor = Colors.teal[50]!;
        icon = Icons.info_outline;
        break;
      case 'warning':
        iconColor = Colors.red;
         bgColor = Colors.red[50]!;
        icon = Icons.error_outline;
        break;
      default:
        iconColor = Colors.grey;
        bgColor = Colors.grey[50]!;
        icon = Icons.notifications;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                  ),
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
                          Text(notification.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                           if (!notification.isRead)
                             const Icon(Icons.circle, color: Colors.yellow, size: 8), // Yellow dot
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(notification.message, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(notification.time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          GestureDetector(
                            onTap: () {
                              context.read<EmployeeNotificationCubit>().markAsRead(notification.id);
                            },
                            child: const Text('Mark as read', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 12)),
                          )
                        ],
                      )
                    ],
                  ),
                ),
                // Close/Delete icon
                 IconButton(
                   icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                   padding: EdgeInsets.zero,
                   constraints: const BoxConstraints(),
                   onPressed: () {}, // Delete logic
                 )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
