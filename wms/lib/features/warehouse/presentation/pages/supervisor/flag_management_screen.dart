import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/core/theme/app_theme.dart';
import 'package:wms/core/widgets/supervisorBottonBar.dart';

class FlagManagementScreen extends StatefulWidget {
  const FlagManagementScreen({super.key});

  @override
  State<FlagManagementScreen> createState() => _FlagManagementScreenState();
}

class _FlagManagementScreenState extends State<FlagManagementScreen> {
  int _currentIndex = 3; // Flags tab
  String _selectedFilter = 'Tous';
  
  final List<String> _filters = ['Tous', 'En Attente', 'En Cours', 'Résolu'];
  
  // Mock Data
  final List<Map<String, dynamic>> _flags = [
    {
      'id': 'FLG-001',
      'type': 'DAMAGED',
      'priority': 'HIGH',
      'description': 'Produit endommagé lors du déchargement.',
      'location': 'Zone A - Gate 1',
      'reporter': 'John Doe',
      'time': 'Il y a 5 min',
      'status': 'En Attente',
      'task_ref': 'RCP-2026-001'
    },
    {
      'id': 'FLG-002',
      'type': 'QUANTITY',
      'priority': 'MEDIUM',
      'description': 'Quantité reçue (45) différente de la commande (50).',
      'location': 'B7-N2-C5',
      'reporter': 'Sarah Smith',
      'time': 'Il y a 12 min',
      'status': 'En Attente',
      'task_ref': 'STR-2026-002'
    },
     {
      'id': 'FLG-003',
      'type': 'LOCATION',
      'priority': 'LOW',
      'description': 'Étiquette emplacement illisible.',
      'location': 'A3-N1-C8',
      'reporter': 'Mike Johnson',
      'time': 'Il y a 25 min',
      'status': 'En Cours',
      'task_ref': 'PCK-2026-003'
    },
  ];

  void _onNavBarTap(int index) {
      if (index == _currentIndex) return;
      
      setState(() {
        _currentIndex = index;
      });
      
      switch (index) {
        case 0:
          Navigator.pushReplacementNamed(context, '/supervisor/dashboard');
          break;
        case 1:
          Navigator.pushReplacementNamed(context, '/supervisor/map');
          break;
        case 2:
          Navigator.pushReplacementNamed(context, '/supervisor/review');
          break;
        case 3:
          break;
      }
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.veryLightGrey,
      appBar: AppBar(
        title: Text('Gestion des Signalements', style: GoogleFonts.lato(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _flags.length,
              itemBuilder: (context, index) {
                final flag = _flags[index];
                if (_selectedFilter != 'Tous' && flag['status'] != _selectedFilter) {
                  return const SizedBox.shrink();
                }
                return _buildFlagCard(flag);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SupervisorBottomBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(filter, style: GoogleFonts.lato(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                )),
                selected: isSelected,
                selectedColor: AppTheme.darkBlue,
                backgroundColor: Colors.grey[100],
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildFlagCard(Map<String, dynamic> flag) {
    Color typeColor = AppTheme.lightBlue;
    if (flag['type'] == 'DAMAGED') typeColor = AppTheme.red;
    if (flag['type'] == 'QUANTITY') typeColor = AppTheme.yellow;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    flag['type'],
                    style: GoogleFonts.lato(color: typeColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Text(flag['status'], style: GoogleFonts.lato(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              flag['description'],
              style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
             Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${flag['reporter']} • ${flag['location']}', style: GoogleFonts.lato(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Réf: ${flag['task_ref']}',
              style: GoogleFonts.lato(color: Colors.grey[500], fontSize: 12),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: Text('Réassigner', style: GoogleFonts.lato(color: AppTheme.darkBlue)),
                  ),
                ),
                const SizedBox(width: 12),
                 Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.yellow,
                      foregroundColor: Colors.black87,
                    ),
                    child: Text('Résoudre', style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
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
