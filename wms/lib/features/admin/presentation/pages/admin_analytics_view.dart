import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/core/theme/app_theme.dart';
import 'package:wms/core/widgets/layout/admin_app_bar.dart';

class AdminAnalyticsView extends StatelessWidget {
  const AdminAnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.veryLightGrey,
      appBar: AdminAppBar(
        title: 'Statistiques Opérationnelles',
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Color(0xFF5D6266)),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildQuickStats(),
          const SizedBox(height: 24),
          _buildChartPlaceholder('Flux de Réception vs Expédition', 'Volume hebdomadaire'),
          const SizedBox(height: 16),
          _buildChartPlaceholder('Productivité de l\'Équipe', 'Tâches complétées par heure'),
          const SizedBox(height: 16),
          _buildChartPlaceholder('Taux d\'Erreur par Zone', 'Analyse du dernier mois'),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Throughput', '1,240', 'items/day', Icons.speed, Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('Accuracy', '98.5%', '+0.2%', Icons.check_circle_outline, Colors.green)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String trend, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(trend, style: GoogleFonts.lato(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildChartPlaceholder(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(subtitle, style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 24),
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(12)),
            child: Center(
              child: Icon(Icons.bar_chart, size: 48, color: Colors.grey[300]),
            ),
          ),
        ],
      ),
    );
  }
}
