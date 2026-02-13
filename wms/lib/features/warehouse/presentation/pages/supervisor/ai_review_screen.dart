import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/core/widgets/supervisorBottonBar.dart';
import 'package:wms/features/warehouse/presentation/cubits/supervisor/ai_review_cubit.dart';
import 'package:wms/features/warehouse/data/models/ai_override_model.dart';
import 'package:wms/core/theme/app_theme.dart';

class AiReviewScreen extends StatefulWidget {
  const AiReviewScreen({super.key});

  @override
  State<AiReviewScreen> createState() => _AiReviewScreenState();
}

class _AiReviewScreenState extends State<AiReviewScreen> {
  int _currentIndex = 2; // AI tab
  String _selectedTab = 'Preparation Orders';

  void _onNavBarTap(int index) {
    if (index == _currentIndex) return; // Don't navigate if already on this page
    
    setState(() {
      _currentIndex = index;
    });
    
    // Handle navigation based on index
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/supervisor/dashboard');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/supervisor/map');
        break;
      case 2:
        // Already on AI review
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
                      'File de validation IA',
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Show approve multiple dialog
                        _showApproveMultipleDialog(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.green,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check, size: 16, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            'Approuver tout',
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
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
                      child: _buildTabButton('Commandes préparation', 'Preparation Orders'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTabButton('Affectations stockage', 'Storage Assignments'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTabButton('Préparation', 'Picking'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: BlocBuilder<AiReviewCubit, AiReviewState>(
              builder: (context, state) {
                if (state is AiReviewLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is AiReviewLoaded) {
                  if (state.pendingOrders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 64, color: AppTheme.green),
                          const SizedBox(height: 16),
                          Text(
                            'Toutes les suggestions IA examinées!',
                            style: GoogleFonts.lato(fontSize: 16, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.pendingOrders.length,
                    itemBuilder: (context, index) {
                      final order = state.pendingOrders[index];
                      return _buildOrderCard(context, order);
                    },
                  );
                } else if (state is AiReviewError) {
                  return Center(
                    child: Text(
                      state.message,
                      style: GoogleFonts.lato(color: AppTheme.red),
                    ),
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
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.lightBlue : Colors.grey.shade300,
          ),
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
    bool isPrep = order['type'] == AiOrderType.preparation;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.lightBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'OPTIMISATION IA',
                        style: GoogleFonts.lato(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  order['id'],
                  style: GoogleFonts.lato(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton(
                  icon: Icon(Icons.more_vert, color: Colors.grey[600], size: 20),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: Text('Voir les détails', style: GoogleFonts.lato()),
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              order['product'],
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            if (isPrep) ...[
              _buildDataRow('ORD:', order['id'], Colors.grey[700]!),
              _buildDataRow('SKU:', order['sku'] ?? 'N/A', Colors.grey[700]!),
              _buildDataRow('Produit à choisir:', order['product'], Colors.grey[700]!),
              _buildDataRow('Itinéraire:', order['route'] ?? 'A3-N1-C9', Colors.grey[700]!),
              _buildDataRow('Nombre:', order['number'] ?? 'B2-N1-C1', Colors.grey[700]!),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppTheme.green, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Route Zone A → Zone B',
                        style: GoogleFonts.lato(
                          fontSize: 11,
                          color: AppTheme.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.percent, color: Colors.grey[600], size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '95% plus rapide',
                    style: GoogleFonts.lato(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ] else ...[
              _buildDataRow('Suggestion IA', '${order['ai_quantity']} unités', AppTheme.lightBlue),
              _buildDataRow('Stock actuel', '${order['current_stock']} unités', AppTheme.red),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showOverrideDialog(context, order),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: AppTheme.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.close, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Remplacer',
                          style: GoogleFonts.lato(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.read<AiReviewCubit>().approveOrder(order['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.lightBlue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check, size: 16, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          'Approuver',
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
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
    );
  }

  Widget _buildDataRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.lato(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.lato(
                color: valueColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  void _showOverrideDialog(BuildContext context, Map<String, dynamic> order) {
    final TextEditingController justificationController = TextEditingController();
    final TextEditingController quantityController = TextEditingController(text: order['ai_quantity']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Remplacer la recommandation IA',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Suggestion IA:',
                style: GoogleFonts.lato(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                order['id'],
                style: GoogleFonts.lato(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Text(
                'Raison du remplacement',
                style: GoogleFonts.lato(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              if (order['type'] == AiOrderType.preparation)
                TextField(
                  controller: quantityController,
                  decoration: InputDecoration(
                    labelText: 'Quantité finale',
                    labelStyle: GoogleFonts.lato(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: AppTheme.veryLightGrey,
                  ),
                  keyboardType: TextInputType.number,
                ),
              const SizedBox(height: 12),
              Text(
                'Justification *',
                style: GoogleFonts.lato(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: justificationController,
                decoration: InputDecoration(
                  hintText: 'Expliquez pourquoi vous remplacez la suggestion IA...',
                  hintStyle: GoogleFonts.lato(color: Colors.grey[400]),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: AppTheme.veryLightGrey,
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 8),
              Text(
                '1000 caractères minimum',
                style: GoogleFonts.lato(fontSize: 10, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: GoogleFonts.lato(color: Colors.grey[700]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (justificationController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'La justification est requise',
                      style: GoogleFonts.lato(),
                    ),
                    backgroundColor: AppTheme.red,
                  ),
                );
                return;
              }
              context.read<AiReviewCubit>().overrideOrder(
                    orderId: order['id'],
                    justification: justificationController.text,
                    finalDecision: {
                      'final_quantity': int.tryParse(quantityController.text) ?? order['ai_quantity'],
                    },
                  );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.yellow,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Confirmer le remplacement',
              style: GoogleFonts.lato(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showApproveMultipleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.yellow,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 32, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'Approuver toutes les sélections (3)',
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: GoogleFonts.lato(color: Colors.grey[700])),
          ),
          ElevatedButton(
            onPressed: () {
              // Approve all logic
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.yellow,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Approuver',
              style: GoogleFonts.lato(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}