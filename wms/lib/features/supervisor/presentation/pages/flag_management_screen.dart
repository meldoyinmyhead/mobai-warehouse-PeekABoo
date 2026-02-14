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
          Navigator.pushReplacementNamed(context, '/supervisor/ai_review');
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
    // Colors based on the design image
    const Color leftBorderColor = Color(0xFF006D84); // User requested specific teal
    Color iconBgColor = const Color(0xFFE0F2F1); // Light Teal
    Color iconColor = const Color(0xFF00796B); // Teal
    
    if (flag.type == FlagType.DAMAGED) {
      iconBgColor = const Color(0xFFFFEBEE); // Light Red
      iconColor = const Color(0xFFD32F2F); // Red
    } else if (flag.type == FlagType.QUANTITY) {
      iconBgColor = const Color(0xFFE3F2FD); // Light Blue
      iconColor = const Color(0xFF1976D2); // Blue
    }

    String statusText = 'Pending';
    Color statusBg = Colors.blue.withOpacity(0.1);
    Color statusTextColor = Colors.blue;
    
    if (flag.status == FlagStatus.IN_PROGRESS) {
      statusText = 'In Review';
      statusBg = Colors.orange.withOpacity(0.1);
      statusTextColor = Colors.orange[800]!;
    } else if (flag.status == FlagStatus.RESOLVED) {
      statusText = 'Resolved';
      statusBg = Colors.green.withOpacity(0.1);
      statusTextColor = Colors.green;
    }

    // Simple time ago logic
    final now = DateTime.now();
    final diff = now.difference(flag.createdAt);
    String timeAgo = '${diff.inMinutes} mins ago';
    if (diff.inMinutes > 60) timeAgo = '${diff.inHours} hours ago';
    if (diff.inHours > 24) timeAgo = '${diff.inDays} days ago';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left "Green Thingy" Border
            Container(
              width: 6,
              color: leftBorderColor,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon Circle
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: iconBgColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIconForType(flag.type),
                            color: iconColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Main Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Tags Row
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: iconBgColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      flag.type.name,
                                      style: GoogleFonts.lato(
                                        color: iconColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusBg,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: GoogleFonts.lato(
                                        color: statusTextColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Title
                              Text(
                                flag.description.isNotEmpty ? flag.description : 'Signalement #${flag.id.substring(0, 8)}',
                                style: GoogleFonts.lato(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              // Details: User
                              Row(
                                children: [
                                  Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    flag.reporterName ?? 'Unknown User',
                                    style: GoogleFonts.lato(color: Colors.grey[600], fontSize: 13),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    flag.locationCode ?? 'No Loc',
                                    style: GoogleFonts.lato(color: Colors.grey[600], fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Details: Content Text
                              Text(
                                flag.description, // Or a separate specific text if description is used for title
                                style: GoogleFonts.lato(color: Colors.grey[500], fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              // Footer
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.access_time, size: 14, color: Colors.grey[400]),
                                      const SizedBox(width: 4),
                                      Text(
                                        timeAgo,
                                        style: GoogleFonts.lato(color: Colors.grey[400], fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  if (flag.status != FlagStatus.RESOLVED)
                                  GestureDetector(
                                    onTap: () => _showActionSheet(context, flag),
                                    child: Row(
                                      children: [
                                        Icon(Icons.arrow_forward, size: 14, color: Colors.blue[300]),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Actions',
                                          style: GoogleFonts.lato(color: Colors.blue[300], fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ],
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
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(FlagType type) {
    switch (type) {
      case FlagType.DAMAGED: return Icons.cancel_outlined;
      case FlagType.QUANTITY: return Icons.info_outline;
      case FlagType.LOCATION: return Icons.place_outlined; // Replaces MISPLACEMENT
      case FlagType.OTHER: return Icons.help_outline; // Replaces QUALITY/default
      default: return Icons.warning_amber_rounded;
    }
  }

  void _showActionSheet(BuildContext context, FlagModel flag) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                title: const Text('Resolve'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<FlagCubit>().resolveFlag(flag.id);
                },
              ),
               ListTile(
                leading: const Icon(Icons.pending_actions, color: Colors.orange),
                title: const Text('Mark In Progress'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<FlagCubit>().setFlagInProgress(flag.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
