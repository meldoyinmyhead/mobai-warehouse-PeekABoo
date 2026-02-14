import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/core/theme/app_theme.dart';
import 'package:wms/core/widgets/layout/admin_app_bar.dart';

class AdminAiConfigView extends StatefulWidget {
  const AdminAiConfigView({super.key});

  @override
  State<AdminAiConfigView> createState() => _AdminAiConfigViewState();
}

class _AdminAiConfigViewState extends State<AdminAiConfigView> {
  double _forecastThreshold = 0.90;
  bool _autoApproveForecast = false;
  double _storageThreshold = 0.85;
  bool _autoApproveStorage = true;
  double _pickingThreshold = 0.88;
  String _pickingAlgorithm = 'HYBRIDE';
  bool _congestionAvoidance = true;
  final TextEditingController _overrideController = TextEditingController();

  @override
  void dispose() {
    _overrideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AdminAppBar(title: 'Configuration de l\'IA'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeaderBanner(),
            _buildStatusDashboard(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildForecastSection(),
                  const SizedBox(height: 16),
                  _buildStorageSection(),
                  const SizedBox(height: 16),
                  _buildPickingSection(),
                  const SizedBox(height: 16),
                  _buildOverrideParamsSection(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: const BoxDecoration(
        color: Color(0xFFE8F4F8),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            bottom: 0,
            child: Opacity(
              opacity: 0.8,
              child: Image.network(
                'https://illustrations.popsy.co/emerald/software-engineer.svg',
                height: 150,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Configuration des services d\'IA',
                  style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF006D77)),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 200,
                  child: Text(
                    'Gérer les algorithmes d\'IA et seuils',
                    style: GoogleFonts.lato(fontSize: 12, color: const Color(0xFF5D6266)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDashboard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildStatusDot('Prévision', Colors.green),
              const SizedBox(width: 12),
              _buildStatusDot('Stockage', Colors.green),
              const SizedBox(width: 12),
              _buildStatusDot('Cueillette', Colors.grey),
            ],
          ),
          Text(
            'Confiance : 88 %',
            style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF4A9B9F)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDot(String label, Color color) {
    return Row(
      children: [
        Icon(Icons.circle, color: color, size: 8),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.lato(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildForecastSection() {
    return _buildConfigCard(
      title: 'Service de prévision',
      subtitle: 'Prévision et planification de la demande',
      icon: Icons.show_chart_outlined,
      child: Column(
        children: [
          _buildSliderRow('Seuil de confiance', _forecastThreshold, (val) => setState(() => _forecastThreshold = val)),
          _buildSwitchRow('Approuver automatiquement si confiance', _autoApproveForecast, (val) => setState(() => _autoApproveForecast = val)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMetricTile('Précision', '94%')),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricTile('Remplacements', '5')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStorageSection() {
    return _buildConfigCard(
      title: 'Optimisation du stockage',
      subtitle: 'Localisation et gestion des espaces',
      icon: Icons.smart_toy_outlined,
      child: Column(
        children: [
          _buildSliderRow('Seuil de confiance', _storageThreshold, (val) => setState(() => _storageThreshold = val)),
          _buildSwitchRow('Approuver automatiquement si confiance', _autoApproveStorage, (val) => setState(() => _autoApproveStorage = val)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMetricTile('Efficacité', '87%')),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricTile('Distance économisée', '45m')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPickingSection() {
    return _buildConfigCard(
      title: 'Optimisation du prélèvement',
      subtitle: 'Optimisation des itinéraires et des séquences',
      icon: Icons.timeline_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSliderRow('Seuil de confiance', _pickingThreshold, (val) => setState(() => _pickingThreshold = val)),
          const SizedBox(height: 12),
          Text('Algorithme', style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildAlgoButton('LE PLUS COURT'),
              const SizedBox(width: 8),
              _buildAlgoButton('LE PLUS RAPIDE'),
              const SizedBox(width: 8),
              _buildAlgoButton('HYBRIDE'),
            ],
          ),
          const SizedBox(height: 16),
          _buildSwitchRow('Évitement des embouteillages', _congestionAvoidance, (val) => setState(() => _congestionAvoidance = val)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildMetricTile('Temps gagné', '45 minutes')),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricTile('Précision', '91%')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlgoButton(String label) {
    bool isSelected = _pickingAlgorithm == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _pickingAlgorithm = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFDB913) : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? const Color(0xFFFDB913) : Colors.grey[300]!),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverrideParamsSection() {
    return _buildConfigCard(
      title: 'Remplacer les paramètres',
      subtitle: 'Ajuster les comportements manuellement',
      icon: Icons.settings_backup_restore_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Justification requise', style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 8),
          TextField(
            controller: _overrideController,
            maxLines: 3,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text('Caractères minimum : 50', style: GoogleFonts.lato(fontSize: 10, color: const Color(0xFF4A9B9F))),
          ),
          const SizedBox(height: 12),
          _buildSliderRow('Seuil de confiance', 0.5, (val) {}),
        ],
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
              backgroundColor: const Color(0xFF006D77),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: Text(
              'ENREGISTRER LA CONFIGURATION',
              style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFDB913)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'RÉINITIALISATION AUX DÉFAUTS',
              style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF5D6266)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfigCard({required String title, required String subtitle, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4A9B9F).withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFF0F7F8), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: const Color(0xFF4A9B9F), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold)),
                    Text(subtitle, style: GoogleFonts.lato(fontSize: 11, color: Colors.grey[500])),
                  ],
                ),
              ),
              Switch(value: true, onChanged: (v) {}, activeColor: const Color(0xFF34495E)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSliderRow(String label, double value, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[600])),
            Text('${(value * 100).toInt()}%', style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF4A9B9F))),
          ],
        ),
        Slider(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFFBDC3C7),
          inactiveColor: Colors.grey[200],
        ),
      ],
    );
  }

  Widget _buildSwitchRow(String label, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[700]))),
          Switch(value: value, onChanged: onChanged, activeColor: const Color(0xFF34495E)),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.lato(fontSize: 10, color: Colors.grey[500])),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF006D77))),
        ],
      ),
    );
  }
}
