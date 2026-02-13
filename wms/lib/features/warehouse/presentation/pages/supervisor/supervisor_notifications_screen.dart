import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/core/theme/app_theme.dart';

class SupervisorNotificationsScreen extends StatefulWidget {
  const SupervisorNotificationsScreen({super.key});

  @override
  State<SupervisorNotificationsScreen> createState() =>
      _SupervisorNotificationsScreenState();
}

class _SupervisorNotificationsScreenState
    extends State<SupervisorNotificationsScreen> {
  String _selectedFilter = 'Tous';
  late List<NotificationItemModel> notifications;

  @override
  void initState() {
    super.initState();
    notifications = [
      NotificationItemModel(
        id: '1',
        title: 'Produit endommagé - Jean Dupont',
        message:
            'Réception #REC-001 - Plusieurs articles endommagés lors du déchargement',
        category: 'flags',
        type: 'warning',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        isRead: false,
      ),
      NotificationItemModel(
        id: '2',
        title: 'Écart de quantité - Sarah',
        message:
            'Stockage #STOR-15 - Écart de quantité détecté - Révision requise',
        category: 'flags',
        type: 'warning',
        timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
        isRead: false,
      ),
      NotificationItemModel(
        id: '3',
        title: 'Approbation IA requise',
        message: '12 SKU en suggestions en attente de votre examen',
        category: 'ai',
        type: 'info',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: false,
      ),
      NotificationItemModel(
        id: '4',
        title: 'Tâche terminée',
        message: 'Mike Johnson a terminé Préparation #PICK-024-001',
        category: 'tasks',
        type: 'success',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: true,
      ),
      NotificationItemModel(
        id: '5',
        title: 'Alerte système',
        message: 'Zone B de l\'entépôt atteint sa capacité maximale',
        category: 'system',
        type: 'warning',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        isRead: true,
      ),
      NotificationItemModel(
        id: '6',
        title: 'Remplacement IA enregistré',
        message:
            'Votre remplacement pour l\'affectation de stockage STOR-025 a été consigné',
        category: 'ai',
        type: 'info',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        isRead: true,
      ),
    ];
  }

  List<NotificationItemModel> _getFilteredNotifications() {
    if (_selectedFilter == 'Tous') {
      return notifications;
    } else if (_selectedFilter == 'Non lus') {
      return notifications.where((n) => !n.isRead).toList();
    } else {
      return notifications
          .where(
            (n) => n.category.toLowerCase() == _selectedFilter.toLowerCase(),
          )
          .toList();
    }
  }

  int _getUnreadCount() {
    return notifications.where((n) => !n.isRead).length;
  }

  void _markAsRead(String id) {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      setState(() {
        notifications[index].isRead = true;
      });
    }
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in notifications) {
        notification.isRead = true;
      }
    });
  }

  void _deleteNotification(String id) {
    setState(() {
      notifications.removeWhere((n) => n.id == id);
    });
  }

  void _clearAll() {
    setState(() {
      notifications.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotifications = _getFilteredNotifications();
    final unreadCount = _getUnreadCount();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F2F2),
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.lato(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
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
          // Header with notification image
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

          // Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                children: [
                  _buildFilterTab('Tous', 'Tous'),
                  _buildFilterTab('Non lus', 'Non lus'),
                  _buildFilterTab('Signalements', 'flags'),
                  _buildFilterTab('IA', 'ai'),
                  _buildFilterTab('Tâches', 'tasks'),
                  _buildFilterTab('Système', 'system'),
                ],
              ),
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _markAllAsRead,
                  child: Text(
                    'Marquer comme lu',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkBlue,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _clearAll,
                  child: Text(
                    'Tout supprimer',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.red,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Notifications List
          Expanded(
            child: filteredNotifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Pas de notifications',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: filteredNotifications.length,
                    itemBuilder: (context, index) {
                      final notification = filteredNotifications[index];
                      return _buildNotificationCard(notification);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, String filter) {
    final isSelected = _selectedFilter == filter;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = filter;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.darkBlue : Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItemModel notification) {
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: GoogleFonts.lato(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          // Close button
                          GestureDetector(
                            onTap: () => _deleteNotification(notification.id),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatTime(notification.timestamp),
                            style: GoogleFonts.lato(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                          if (!notification.isRead)
                            GestureDetector(
                              onTap: () => _markAsRead(notification.id),
                              child: Text(
                                'Mark as read',
                                style: GoogleFonts.lato(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.lightBlue,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return 'il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'il y a ${difference.inDays} j';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

class NotificationItemModel {
  final String id;
  final String title;
  final String message;
  final String category;
  final String type;
  final DateTime timestamp;
  bool isRead;

  NotificationItemModel({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.type,
    required this.timestamp,
    required this.isRead,
  });
}
