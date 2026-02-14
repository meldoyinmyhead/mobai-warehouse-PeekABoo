import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/core/theme/app_theme.dart';

class StorageFloorsScreen extends StatelessWidget {
  const StorageFloorsScreen({super.key});

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
        title: Text(
          'Storage Floors',
          style: GoogleFonts.lato(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.lightBlue),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildFloorTabs(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildFloorCard('RDC', 'Rez-de-chaussée de stockage', 150, 98, 52, 65, true),
                _buildFloorCard('Nord 2 (N2)', 'Deuxième étage de stockage', 150, 102, 48, 68, false),
                _buildFloorCard('Nord 3 (N3)', 'Troisième étage de stockage', 140, 88, 52, 63, false),
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
            'Étages de Stockage',
            style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkBlue),
          ),
          const SizedBox(height: 4),
          Text(
            '5 floors configured',
            style: GoogleFonts.lato(fontSize: 13, color: AppTheme.darkBlue.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildFloorTabs() {
    return Container(
      height: 60,
      color: Colors.white,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildTab('RDC', true),
          _buildTab('N1', false),
          _buildTab('N2', false),
          _buildTab('N3', false),
          _buildTab('N4', false),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool active) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: active ? AppTheme.veryLightGrey : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 12,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: active ? AppTheme.darkBlue : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildFloorCard(String name, String desc, int total, int occup, int avail, int capacity, bool hasSmallGrid) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.layers_outlined, color: AppTheme.lightBlue, size: 20),
                        const SizedBox(width: 8),
                        Text(name, style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Row(
                      children: [
                        Text('$capacity%', style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.lightBlue)),
                        const SizedBox(width: 4),
                        Text('Capacité', style: GoogleFonts.lato(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const SizedBox(width: 28),
                    Text(desc, style: GoogleFonts.lato(fontSize: 11, color: Colors.grey[500])),
                  ],
                ),
              ],
            ),
          ),
          if (hasSmallGrid)
             Container(
               height: 120,
               margin: const EdgeInsets.symmetric(horizontal: 16),
               decoration: BoxDecoration(
                 color: AppTheme.veryLightGrey,
                 borderRadius: BorderRadius.circular(8),
                 image: const DecorationImage(
                   image: AssetImage('assets/images/floor_grid.png'), // Placeholder
                   fit: BoxFit.cover,
                   opacity: 0.5,
                 ),
               ),
               child: const Center(child: Icon(Icons.fullscreen, color: Colors.grey)),
             ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFloorStat('Total', total.toString()),
                _buildFloorStat('Occupé', occup.toString(), color: AppTheme.lightBlue),
                _buildFloorStat('Disponible', avail.toString(), color: Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloorStat(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.lato(fontSize: 10, color: Colors.grey[500])),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold, color: color ?? Colors.black87)),
      ],
    );
  }
}
