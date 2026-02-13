import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart';
import 'package:wms/features/warehouse/data/models/task_model.dart';
import 'package:wms/core/theme/app_theme.dart';
import 'package:wms/features/warehouse/presentation/widgets/task_views/flag.dart';

class DeliveryTaskView extends StatelessWidget {
  final TaskModel task;

  const DeliveryTaskView({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailsCard(),
        const SizedBox(height: 16),
        _buildDestinationCard(),
        const SizedBox(height: 16),
        _buildProductList(),
        const SizedBox(height: 16),
        _buildConfirmationCard(),
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
              'Détails de livraison',
              style: GoogleFonts.lato(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const Divider(),
            _buildDetailRow('Numéro de commande:', task.description.replaceAll('Order: ', '')),
            _buildDetailRow('Type de livraison:', task.details['delivery_type'] ?? 'N/A'),
            _buildDetailRow('Quai de chargement:', task.details['loading_bay'] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: AppTheme.lightBlue, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.details['destination'] ?? 'Inconnu',
                        style: GoogleFonts.lato(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        task.details['address'] ?? '',
                        style: GoogleFonts.lato(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppTheme.lightBlue.withOpacity(0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Personne à contacter:', task.details['contact_person'] ?? 'N/A'),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {
                    // Launch dialer
                  },
                  child: Text(
                    task.details['contact_number'] ?? 'N/A',
                    style: GoogleFonts.lato(
                      color: AppTheme.lightBlue,
                      decoration: TextDecoration.underline,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Heure de livraison estimée',
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.veryLightGrey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.details['estimated_time'] ?? 'N/A',
                    style: GoogleFonts.lato(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.darkBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Liste des produits',
              style: GoogleFonts.lato(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
          ...task.products.map((product) => Column(
                children: [
                  ListTile(
                    title: Text(
                      product.name,
                      style: GoogleFonts.lato(fontSize: 14),
                    ),
                    trailing: Text(
                      '${product.expectedQuantity} unités',
                      style: GoogleFonts.lato(
                        color: AppTheme.lightBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                ],
              )),
        ],
      ),
    );
  }

  Widget _buildConfirmationCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirmation de livraison',
              style: GoogleFonts.lato(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Horodatage de livraison', '11:45 PM - 12 Fév, 2026'),
            const SizedBox(height: 16),
            Text(
              'Nom/Signature du destinataire',
              style: GoogleFonts.lato(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: 'Entrez le nom du destinataire...',
                hintStyle: GoogleFonts.lato(color: Colors.grey[400]),
                filled: true,
                fillColor: AppTheme.veryLightGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Facultatif - Signature numérique ou confirmation du destinataire',
              style: GoogleFonts.lato(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Notes de livraison (Facultatif)',
              style: GoogleFonts.lato(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: 'Ajouter des notes de livraison...',
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
              elevation: 0,
            ),
            child: Text(
              'Confirmer la livraison',
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
              backgroundColor: AppTheme.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
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