import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms/core/theme/app_theme.dart';
import 'package:wms/features/auth/presentation/cubits/employee_notification_cubit.dart';

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
      backgroundColor: const Color(0xFFF4F2F2),
      appBar: AppBar(
        title: const Text('Dernières notifications'),
        backgroundColor: const Color(0xFFF4F2F2),
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            height: 170,
            width: MediaQuery.of(context).size.width,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/notification.png"),
                fit: BoxFit.cover,
              ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    Color iconColor;
    IconData icon;

    switch (notification.type) {
      case 'success':
        iconColor = AppTheme.yellow;
        icon = Icons.check_circle_outline;
        break;
      case 'info':
        iconColor = AppTheme.lightBlue;
        icon = Icons.info_outline;
        break;
      case 'warning':
        iconColor = AppTheme.red;
        icon = Icons.error_outline;
        break;
      default:
        iconColor = Colors.grey;
        icon = Icons.notifications;
    }

    return Card(
      color: Colors.white,
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
                    color: iconColor.withOpacity(0.1),
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
                        children: [
                          Text(
                            notification.title == 'Task completed'
                                ? 'Tâche terminée'
                                : notification.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(width: 6),
                          if (!notification.isRead && notification.title == 'Task completed')
                            const Icon(Icons.circle, color: Colors.yellow, size: 8),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            notification.time,
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          GestureDetector(
                            onTap: () {
                              context
                                  .read<EmployeeNotificationCubit>()
                                  .markAsRead(notification.id);
                            },
                            child: const Text(
                              'Marquer comme lu',
                              style: TextStyle(
                                  color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
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
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
