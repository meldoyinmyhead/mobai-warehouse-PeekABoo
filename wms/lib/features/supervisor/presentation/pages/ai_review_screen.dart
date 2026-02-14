import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/core/widgets/layout/supervisorBottonBar.dart';
import 'package:wms/features/supervisor/presentation/cubits/ai_review_cubit.dart';
import 'package:wms/features/supervisor/data/models/ai_override_model.dart';
import 'package:wms/core/theme/app_theme.dart';


class AiReviewScreen extends StatefulWidget {
  const AiReviewScreen({super.key});

  @override
  State<AiReviewScreen> createState() => _AiReviewScreenState();
}

class _AiReviewScreenState extends State<AiReviewScreen> {
  int _currentIndex = 2; // AI tab
  String _selectedTab = 'Preparation Orders';

  @override
  void initState() {
    super.initState();
    context.read<AiReviewCubit>().loadPendingReviews();
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
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/supervisor/flagged');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.veryLightGrey,
       appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(12.0),
            child: CircleAvatar(
              backgroundColor: Colors.grey[200],
              child: const Icon(Icons.person_outline, color: Color(0xFF5D6266)),
            ),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Image.asset('assets/images/logo.png', height: 30)],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Color(0xFF5D6266)),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Color(0xFF5D6266)),
              onPressed: () {},
            ),
          ],
        ),
      body: Column(
        children: [
          // Header Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'File de Validation IA',
                      style: GoogleFonts.lato(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _showApproveMultipleDialog(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.green,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check, size: 16, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            'Tout Approuver',
                            style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Tab Selector
                Row(
                  children: [
                    Expanded(
                      child: _buildTabButton('Préparation', 'Preparation Orders'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTabButton('Stockage', 'Storage Assignments'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTabButton('Picking', 'Picking'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Expanded(
            child: BlocBuilder<AiReviewCubit, AiReviewState>(
              builder: (context, state) {
                if (state is AiReviewLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is AiReviewLoaded) {
                  final filteredOrders = state.pendingOrders.where((o) {
                    if (_selectedTab == 'Preparation Orders') return o['type'] == AiOrderType.preparation;
                    if (_selectedTab == 'Picking') return o['type'] == AiOrderType.picking;
                    return false; // Storage logic to follow
                  }).toList();

                  if (filteredOrders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 64, color: AppTheme.green),
                          const SizedBox(height: 16),
                          Text(
                            'Toutes les suggestions IA ont été revues !',
                            style: GoogleFonts.lato(fontSize: 16, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      return _buildOrderCard(context, order);
                    },
                  );
                } else if (state is AiReviewError) {
                  return Center(child: Text(state.message, style: GoogleFonts.lato(color: AppTheme.red)));
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

  Widget _buildTabButton(String label, String value) {
    final isSelected = _selectedTab == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.lightBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.lightBlue : Colors.grey.shade300),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order) {
    // Determine colors/texts based on mock design requirements
    final confidence = order['confidence'] ?? 95;
    final forecastDate = order['forecast_date'] as DateTime? ?? DateTime.now();
    final formattedDate = "${forecastDate.day}/${forecastDate.month}/${forecastDate.year}";
    final reasoning = order['reasoning'] ?? "Logique d'optimisation IA appliquée.";

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
            // Left "Teal" Border
            Container(
              width: 6,
              color: const Color(0xFF006D84),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: Colors.black54),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.lightBlue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.smart_toy, color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'GÉNÉRÉ PAR IA',
                                style: GoogleFonts.lato(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          order['reference'] ?? 'REF-???', 
                          style: GoogleFonts.lato(fontWeight: FontWeight.bold, color: Colors.black87)
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Main Content Row (Info + Confidence)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order['product_name'] ?? 'Produit Inconnu',
                                style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'SKU: ${order['sku']}',
                                style: GoogleFonts.lato(fontSize: 14, color: Colors.grey[600]),
                              ),
                              Text(
                                'Quantité: ${order['ai_quantity']} unités',
                                style: GoogleFonts.lato(fontSize: 14, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Date Prévue: $formattedDate (1 jour d\'avance)',
                                style: GoogleFonts.lato(fontSize: 13, color: Colors.blue[400]),
                              ),
                            ],
                          ),
                        ),
                        // Confidence Indicator
                        Column(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  height: 60,
                                  width: 60,
                                  child: CircularProgressIndicator(
                                    value: confidence / 100,
                                    strokeWidth: 5,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.darkGrey),
                                  ),
                                ),
                                 Text(
                                  '$confidence%',
                                  style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Confiance', style: GoogleFonts.lato(fontSize: 10, color: Colors.grey))
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    
                    // Reasoning Dropdown (Custom implementation for simplicity)
                    ExpansionTile(
                      title: Text(
                        'Voir Raisonnement', 
                        style: GoogleFonts.lato(fontSize: 14, color: AppTheme.lightBlue, fontWeight: FontWeight.w600)
                      ),
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: EdgeInsets.zero,
                      iconColor: AppTheme.lightBlue,
                      collapsedIconColor: AppTheme.lightBlue,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            reasoning,
                            style: GoogleFonts.lato(fontSize: 13, color: Colors.black54, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => context.read<AiReviewCubit>().approveOrder(order['id'], order['type']),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.lightBlue,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Approuver', 
                                  style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _showOverrideDialog(context, order),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: AppTheme.yellow, width: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.close, color: AppTheme.darkGrey, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Remplacer', 
                                  style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkBlue)
                                ),
                              ],
                            ),
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

  void _showOverrideDialog(BuildContext context, Map<String, dynamic> order) {
    final TextEditingController justificationController = TextEditingController();
    String? selectedReason;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: const Color(0xFFFEFEFE),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Remplacer Recommandation IA',
                          style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(dialogContext),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // AI Suggestion Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Suggestion IA :', style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                          const SizedBox(height: 4),
                          Text(
                            order['reference'] ?? 'Commande Inconnue',
                            style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Text('Raison du Remplacement', style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                        hintText: 'Sélectionnez la raison',
                      ),
                      value: selectedReason,
                      items: [
                        'Emplacement occupé',
                        'Équipement indisponible',
                        'Problème de sécurité',
                        'Priorité opérationnelle',
                        'Autre'
                      ].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: GoogleFonts.lato(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => selectedReason = val);
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Text('Justification *', style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: justificationController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Expliquez pourquoi vous remplacez cette suggestion... (min 20 caractères)',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('20 caractères minimum', style: GoogleFonts.lato(fontSize: 11, color: Colors.grey[600])),
                    
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                           if (selectedReason == null) return;
                           // Add validation logic here
                          context.read<AiReviewCubit>().overrideOrder(
                            orderId: order['id'],
                            orderType: order['type'],
                            justification: '${selectedReason}: ${justificationController.text}',
                            aiSuggestion: order,
                            finalDecision: {'reason': selectedReason},
                          );
                          Navigator.pop(dialogContext);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.yellow,
                          foregroundColor: AppTheme.darkBlue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Text('Confirmer Remplacement', style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                     const SizedBox(height: 12),
                     SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          foregroundColor: Colors.black87,
                           padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                         child: Text('Annuler', style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                     ),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  void _showApproveMultipleDialog(BuildContext context) {
    // Basic logic to approve all on page
    Navigator.pop(context);
    // Ideally call cubit to approve all visible
  }
}