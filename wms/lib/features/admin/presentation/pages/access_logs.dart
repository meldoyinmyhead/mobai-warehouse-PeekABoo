import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/core/theme/app_theme.dart';

class AccessLogsScreen extends StatefulWidget {
  const AccessLogsScreen({super.key});

  @override
  State<AccessLogsScreen> createState() => _AccessLogsScreenState();
}

class _AccessLogsScreenState extends State<AccessLogsScreen> {
  String _selectedFilter = 'TOUS';
  final TextEditingController _searchController = TextEditingController();

  final List<LogEntry> _logs = [
    LogEntry(
      type: 'Utilisateur créé',
      timestamp: '2024-02-13 14:23:15',
      user: 'Admin Sarah M.',
      entity: 'John Davis (EMP-A4B2C1)',
      details: 'Nouveau compte d\'employé créé avec rôle de superviseur.',
      badge: 'ADMIN',
      badgeColor: Color(0xFFFDB913),
    ),
    LogEntry(
      type: 'Remplacement IA',
      timestamp: '2024-02-13 14:15:42',
      user: 'Superviseur Mike L.',
      entity: 'Tâche de stockage ST-4782',
      details:
          'A remplacé la recommandation d\'emplacement de stockage de l\'IA',
      badge: 'SUPERVISOR',
      badgeColor: Color(0xFF4A9B9F),
    ),
    LogEntry(
      type: 'Mouvement du stock',
      timestamp: '2024-02-13 13:58:27',
      user: 'Système IA',
      entity: 'SKU-4829 (Boulons industriels)',
      details:
          'Réaffectation automatique du stock basée sur la prévision de la demande',
      badge: 'SYSTEM',
      badgeColor: Color(0xFF5D6266),
    ),
    LogEntry(
      type: 'Utilisateur désactivé',
      timestamp: '2024-02-13 13:45:10',
      user: 'Admin Sarah M.',
      entity: 'Mike Johnson (EMP-X9Y2Z1)',
      details: 'Compte utilisateur temporairement désactivé',
      badge: 'ADMIN',
      badgeColor: Color(0xFFFDB913),
    ),
  ];

  List<LogEntry> get _filteredLogs {
    if (_selectedFilter == 'TOUS') return _logs;
    return _logs.where((log) {
      switch (_selectedFilter) {
        case 'UTILISATEUR':
          return log.type.contains('Utilisateur');
        case 'IA':
          return log.type.contains('IA') || log.type.contains('Système');
        case 'REMPLACEMENT':
          return log.type.contains('Remplacement');
        case 'SIGNALEMENT':
          return false;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.veryLightGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Historique d\'accès',
          style: GoogleFonts.lato(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Historique d\'activité système',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enregistrement complet de toutes les actions du système',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      color: const Color(0xFF5D6266),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher les journaux...',
                  hintStyle: GoogleFonts.lato(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('TOUS'),
                  const SizedBox(width: 8),
                  _buildFilterChip('UTILISATEUR'),
                  const SizedBox(width: 8),
                  _buildFilterChip('IA'),
                  const SizedBox(width: 8),
                  _buildFilterChip('REMPLACEMENT'),
                  const SizedBox(width: 8),
                  _buildFilterChip('SIGNALEMENT'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Log Entries
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredLogs.length,
              itemBuilder: (context, index) {
                return _buildLogCard(_filteredLogs[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFDB913) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFDB913) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildLogCard(LogEntry log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: const Color(0xFF27AE60),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  log.type,
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: log.badgeColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  log.badge,
                  style: GoogleFonts.lato(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            log.timestamp,
            style: GoogleFonts.lato(fontSize: 11, color: Colors.grey[500]),
          ),
          const SizedBox(height: 12),
          _buildLogDetail('Utilisateur:', log.user),
          const SizedBox(height: 4),
          _buildLogDetail('Entité:', log.entity),
          const SizedBox(height: 4),
          _buildLogDetail('Détails:', log.details),
        ],
      ),
    );
  }

  Widget _buildLogDetail(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.lato(fontSize: 12, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class LogEntry {
  final String type;
  final String timestamp;
  final String user;
  final String entity;
  final String details;
  final String badge;
  final Color badgeColor;

  LogEntry({
    required this.type,
    required this.timestamp,
    required this.user,
    required this.entity,
    required this.details,
    required this.badge,
    required this.badgeColor,
  });
}