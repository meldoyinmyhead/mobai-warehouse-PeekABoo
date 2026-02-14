import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/core/theme/app_theme.dart';
import 'package:wms/core/widgets/layout/admin_app_bar.dart';
import 'package:wms/features/admin/presentation/pages/admin_ai_config_view.dart';

class AdminSettingsView extends StatefulWidget {
  const AdminSettingsView({super.key});

  @override
  State<AdminSettingsView> createState() => _AdminSettingsViewState();
}

class _AdminSettingsViewState extends State<AdminSettingsView> {
  double _offlineDuration = 4.0;
  double _syncInterval = 30.0;
  double _trackingInterval = 30.0;
  bool _notificationsEnabled = false;
  bool _autoBackup = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AdminAppBar(title: 'Paramètres système'),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildConfigurationHeader(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildOfflineSection(),
                  const SizedBox(height: 16),
                  _buildTrackingSection(),
                  const SizedBox(height: 16),
                  _buildNotificationSection(),
                  const SizedBox(height: 16),
                  _buildBackupSection(),
                  const SizedBox(height: 16),
                  _buildSystemInfoSection(),
                  const SizedBox(height: 24),
                  _buildSaveButton(),
                  const SizedBox(height: 24),
                  _buildAiConfigButton(context),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuration générale',
            style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF2C3E50)),
          ),
          const SizedBox(height: 4),
          Text(
            'Paramètres et préférences à l\'échelle du système',
            style: GoogleFonts.lato(fontSize: 12, color: const Color(0xFF7F8C8D)),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineSection() {
    return _buildSettingsCard(
      title: 'Hors ligne et synchronisation',
      child: Column(
        children: [
          _buildSliderRow('Durée hors ligne', _offlineDuration, 24, 'heures', (v) => setState(() => _offlineDuration = v)),
          const SizedBox(height: 4),
          Text(
            'Durée maximale autorisée pour les opérations hors ligne',
            style: GoogleFonts.lato(fontSize: 10, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          _buildSliderRow('Intervalle de synchronisation', _syncInterval, 300, 'secondes', (v) => setState(() => _syncInterval = v)),
          const SizedBox(height: 4),
          Text(
            'À quelle fréquence synchroniser les données avec le serveur',
            style: GoogleFonts.lato(fontSize: 10, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingSection() {
    return _buildSettingsCard(
      title: 'Suivi de localisation',
      child: Column(
        children: [
          _buildSliderRow('Intervalle de suivi', _trackingInterval, 300, 'secondes', (v) => setState(() => _trackingInterval = v), color: Colors.yellow[700]!),
          const SizedBox(height: 4),
          Text(
            'Fréquence de mise à jour du suivi GPS pour les employés',
            style: GoogleFonts.lato(fontSize: 10, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSection() {
    return _buildSettingsCard(
      title: 'Notifications',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Activer les notifications système', style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[600])),
          Switch(value: _notificationsEnabled, onChanged: (v) => setState(() => _notificationsEnabled = v), activeColor: const Color(0xFF34495E)),
        ],
      ),
    );
  }

  Widget _buildBackupSection() {
    return _buildSettingsCard(
      title: 'Sauvegarde des données',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sauvegarde automatique', style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[600])),
              Switch(value: _autoBackup, onChanged: (v) => setState(() => _autoBackup = v), activeColor: const Color(0xFF34495E)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Dernière sauvegarde', style: GoogleFonts.lato(fontSize: 10, color: Colors.grey[500])),
              Text('Aujourd\'hui, 3h00', style: GoogleFonts.lato(fontSize: 10, color: const Color(0xFF2C3E50))),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sauvegarde suivante', style: GoogleFonts.lato(fontSize: 10, color: Colors.grey[500])),
              Text('Demain, 3h00', style: GoogleFonts.lato(fontSize: 10, color: const Color(0xFF2C3E50))),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFDB913)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'EXÉCUTER UNE SAUVEGARDE MAINTENANT',
                style: GoogleFonts.lato(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF006D77)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemInfoSection() {
    return _buildSettingsCard(
      title: 'Informations système',
      child: Column(
        children: [
          _buildInfoRow('Version de l\'application', '2.1.0'),
          const Divider(),
          _buildInfoRow('Numéro de build', '20240213'),
          const Divider(),
          _buildInfoRow('Dernière mise à jour', '1 février 2024'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[600])),
          Text(value, style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2C3E50))),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
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
          'ENREGISTRER LES PARAMÈTRES',
          style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildAiConfigButton(BuildContext context) {
    return ListTile(
      tileColor: const Color(0xFFF0F7F8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: const Icon(Icons.psychology_outlined, color: Color(0xFF4A9B9F)),
      title: Text('Configuration de l\'IA', style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold)),
      subtitle: Text('Gérer les seuils et comportements de l\'IA', style: GoogleFonts.lato(fontSize: 11)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AdminAiConfigView()),
        );
      },
    );
  }

  Widget _buildSettingsCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF2C3E50))),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSliderRow(String label, double value, double max, String unit, Function(double) onChanged, {Color color = const Color(0xFF4A9B9F)}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[600])),
            Text('${value.toInt()} $unit', style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 12,
            activeTrackColor: const Color(0xFFD9DADC),
            inactiveTrackColor: const Color(0xFFD9DADC),
            thumbColor: Colors.white,
            overlayColor: Colors.transparent,
          ),
          child: Slider(
            value: value,
            min: 0,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
