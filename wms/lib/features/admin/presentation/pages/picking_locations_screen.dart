import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/core/theme/app_theme.dart';

class PickingLocationsScreen extends StatelessWidget {
  const PickingLocationsScreen({super.key});

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emplacements de cueillette',
              style: GoogleFonts.lato(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Entrepôt principal',
              style: GoogleFonts.lato(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view, color: AppTheme.darkBlue),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildStatusSummary(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildLocationCard('A02', 'Eh bien SKU', 'Bloqué', AppTheme.red),
                _buildLocationCard('A03', 'SKU-848', 'Occupé', AppTheme.lightBlue),
                _buildLocationCard('A06', 'Eh bien SKU', 'Bloqué', AppTheme.red),
                _buildLocationCard('A11', 'SKU-802', 'Occupé', AppTheme.lightBlue),
                _buildLocationCard('A13', 'SKU-339', 'Occupé', AppTheme.lightBlue),
                _buildLocationCard('A14', 'SKU-282', 'Occupé', AppTheme.lightBlue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8BB7B9), Color(0xFFC5DDE0)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vue Grille de localisation',
            style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkBlue),
          ),
          const SizedBox(height: 4),
          Text(
            '150 emplacements | 67 disponibles',
            style: GoogleFonts.lato(fontSize: 13, color: AppTheme.darkBlue.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatusBadge('Disponible : 67', Colors.green),
            const SizedBox(width: 8),
            _buildStatusBadge('Occupation : 55', AppTheme.lightBlue),
            const SizedBox(width: 8),
            _buildStatusBadge('Réservé : 15', Colors.amber),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.veryLightGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(String code, String sku, String status, Color accentColor) {
    final bool isBlocked = status == 'Bloqué';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.location_on_outlined, color: accentColor, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            code,
                            style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          Text(
                            sku,
                            style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isBlocked ? const Color(0xFFFFEBEE) : const Color(0xFFE0F2F1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.lato(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isBlocked ? const Color(0xFFC62828) : AppTheme.lightBlue,
                        ),
                      ),
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
}
