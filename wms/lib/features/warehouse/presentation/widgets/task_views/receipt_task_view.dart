import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:wms/core/theme/app_theme.dart';
import 'package:wms/features/warehouse/data/models/task_model.dart';
import 'package:wms/features/warehouse/presentation/widgets/task_views/flag.dart';
import 'package:google_fonts/google_fonts.dart';

class ReceiptTaskView extends StatelessWidget {
  final TaskModel task;

  const ReceiptTaskView({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailsCard(),
        const SizedBox(height: 16),
        Text(
          'Produits attendus',
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        _buildProductsList(),
        const SizedBox(height: 16),
        Text(
          'Exécution de réception',
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        _buildExecutionCard(),
        const SizedBox(height: 24),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Détails de réception',
              style: GoogleFonts.lato(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const Divider(),
            _buildDetailRow('Numéro de commande:', task.description.replaceAll('Order: ', '')),
            _buildDetailRow('Fournisseur:', task.details['supplier'] ?? 'N/A'),
            _buildDetailRow('Arrivée prévue:', task.details['expected_arrival'] ?? 'N/A'),
            _buildDetailRow('Statut:', 'Inspection en attente', color: const Color(0xFF004251)),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsList() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Column(
        children: task.products.map((product) => Column(
              children: [
                ListTile(
                  title: Text(
                    product.name,
                    style: GoogleFonts.lato(fontSize: 14),
                  ),
                  trailing: Text(
                    '${product.expectedQuantity} unités',
                    style: GoogleFonts.lato(
                      color: Color(0xFF006D84),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const Divider(height: 1),
              ],
            )).toList(),
      ),
    );
  }

  Widget _buildExecutionCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...task.products.map((product) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: GoogleFonts.lato(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Attendu: ${product.expectedQuantity}',
                          hintStyle: GoogleFonts.lato(color: Colors.grey[400]),
                          filled: true,
                          fillColor: AppTheme.veryLightGrey,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          suffixText: 'unités',
                          suffixStyle: GoogleFonts.lato(color: Colors.grey[600]),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(value: false, onChanged: (v) {}),
                Expanded(
                  child: Text(
                    'Tous les produits sont arrivés en bon état',
                    style: GoogleFonts.lato(fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Notes (Écarts)',
              style: GoogleFonts.lato(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: 'Entrez les écarts ou notes...',
                hintStyle: GoogleFonts.lato(color: Colors.grey[400]),
                filled: true,
                fillColor: AppTheme.veryLightGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Enregistrer la tâche',
              style: GoogleFonts.lato(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context as BuildContext,
                MaterialPageRoute(
                  builder: (context) => FlagIssueScreen(taskId: task.id),
                ),
              );
            },
            icon: const Icon(Icons.flag_outlined, color: Colors.white, size: 20),
            label: Text(
              'Signaler un problème',
              style: GoogleFonts.lato(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF83737),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.lato(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.lato(
                fontWeight: FontWeight.w600,
                color: color ?? Colors.black87,
                fontSize: 13,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}