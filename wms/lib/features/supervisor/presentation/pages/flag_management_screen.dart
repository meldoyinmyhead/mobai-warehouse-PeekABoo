import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/core/theme/app_theme.dart';
import 'package:wms/core/widgets/layout/supervisorBottonBar.dart';
import 'package:wms/features/supervisor/data/models/flag_model.dart';
import 'package:wms/features/supervisor/presentation/cubits/flag_cubit.dart';

class FlagManagementScreen extends StatefulWidget {
  const FlagManagementScreen({super.key});

  @override
  State<FlagManagementScreen> createState() => _FlagManagementScreenState();
}

class _FlagManagementScreenState extends State<FlagManagementScreen> {
  int _currentIndex = 3; // Flags tab
  String _selectedFilter = 'Tous';
  
  final List<String> _filters = ['Tous', 'PENDING', 'IN_PROGRESS', 'RESOLVED'];

  @override
  void initState() {
    super.initState();
    context.read<FlagCubit>().loadFlags();
  }

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
            child: BlocBuilder<FlagCubit, FlagState>(
              builder: (context, state) {
                if (state is FlagLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is FlagError) {
                  return Center(child: Text(state.message));
                } else if (state is FlagLoaded) {
                  final filteredFlags = state.flags.where((f) {
                    if (_selectedFilter == 'Tous') return true;
                    return f.status.name == _selectedFilter;
                  }).toList();

                  if (filteredFlags.isEmpty) {
                    return Center(
                      child: Text('Aucun signalement trouvé', 
                      style: GoogleFonts.lato(color: Colors.grey))
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredFlags.length,
                    itemBuilder: (context, index) {
                      return _buildFlagCard(filteredFlags[index]);
                    },
                  );
                }
                return const SizedBox.shrink();
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
            String displayFilter = filter;
            if (filter == 'PENDING') displayFilter = 'En Attente';
            if (filter == 'IN_PROGRESS') displayFilter = 'En Cours';
            if (filter == 'RESOLVED') displayFilter = 'Résolu';

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(displayFilter, style: GoogleFonts.lato(
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

  Widget _buildFlagCard(FlagModel flag) {
    Color typeColor = AppTheme.lightBlue;
    if (flag.type == FlagType.DAMAGED) typeColor = AppTheme.red;
    if (flag.type == FlagType.QUANTITY) typeColor = AppTheme.yellow;

    String statusText = 'En Attente';
    if (flag.status == FlagStatus.IN_PROGRESS) statusText = 'En Cours';
    if (flag.status == FlagStatus.RESOLVED) statusText = 'Résolu';

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
                    flag.type.name,
                    style: GoogleFonts.lato(color: typeColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Text(statusText, style: GoogleFonts.lato(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              flag.description,
              style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.house_outlined, size: 16, color: AppTheme.darkBlue),
                const SizedBox(width: 8),
                Text(
                  'Entrepôt: ${flag.warehouseCode ?? 'N/A'}',
                  style: GoogleFonts.lato(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Rapporteur: ${flag.reporterName ?? 'Inconnu'}',
                  style: GoogleFonts.lato(color: Colors.grey[700], fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Emplacement: ${flag.locationCode ?? 'N/A'}',
                  style: GoogleFonts.lato(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (flag.taskRef != null && flag.taskRef!.isNotEmpty)
              Text(
                'Réf. Tâche: ${flag.taskRef}',
                style: GoogleFonts.lato(color: Colors.grey[500], fontSize: 11, fontStyle: FontStyle.italic),
              ),
            const SizedBox(height: 16),
            if (flag.status != FlagStatus.RESOLVED)
              Row(
                children: [
                  if (flag.status == FlagStatus.PENDING)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.read<FlagCubit>().setFlagInProgress(flag.id),
                        child: Text('Traiter', style: GoogleFonts.lato(color: AppTheme.darkBlue)),
                      ),
                    ),
                  if (flag.status == FlagStatus.PENDING) const SizedBox(width: 12),
                   Expanded(
                    child: ElevatedButton(
                      onPressed: () => context.read<FlagCubit>().resolveFlag(flag.id),
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
