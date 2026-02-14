import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/core/theme/app_theme.dart';
import 'package:wms/features/admin/data/models/warehouse_model.dart';
import 'package:wms/core/routes/app_router.dart';

class WarehouseDetailsScreen extends StatelessWidget {
  final WarehouseModel warehouse;
  const WarehouseDetailsScreen({super.key, required this.warehouse});

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
          warehouse.name,
          style: GoogleFonts.lato(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                'ACTIVE',
                style: GoogleFonts.lato(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF2E7D32)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildQuickConfigHeader(),
            const SizedBox(height: 24),
            _buildNavigationGrid(context),
            const SizedBox(height: 24),
            _buildDetailsSection(),
            const SizedBox(height: 24),
            _buildPhysicalConfigCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickConfigHeader() {
    return Container(
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
            'Warehouse Configuration',
            style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkBlue),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage all warehouse settings',
            style: GoogleFonts.lato(fontSize: 12, color: AppTheme.darkBlue.withOpacity(0.7)),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatItem('Capacity', '67%'),
              const Spacer(),
              _buildStatItem('Manager', 'Robert Johnson'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.lato(fontSize: 11, color: AppTheme.darkBlue.withOpacity(0.5))),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkBlue)),
      ],
    );
  }

  Widget _buildNavigationGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildDetailNavLink(context, Icons.layers_outlined, 'Storage Floors', '5 floors configured', AppRouter.adminStorageFloors),
          const SizedBox(height: 12),
          _buildDetailNavLink(context, Icons.location_on_outlined, 'Picking Locations', '150 items | Available: 67', AppRouter.adminPickingLocations),
          const SizedBox(height: 12),
          _buildDetailNavLink(context, Icons.inventory_2_outlined, 'SKU Management', 'Total: 456 | Low Stock: 23', ''),
          const SizedBox(height: 12),
          _buildDetailNavLink(context, Icons.shopping_cart_outlined, 'Chariot Management', '32 total chariots', ''),
        ],
      ),
    );
  }

  Widget _buildDetailNavLink(BuildContext context, IconData icon, String title, String subtitle, String route) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          if (route.isNotEmpty) Navigator.pushNamed(context, route);
        },
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.veryLightGrey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.lightBlue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Warehouse Details', style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildInfoRow('Address', '1234 Industrial Blvd, Detroit, MI 48201'),
                const Divider(),
                _buildInfoRow('Operating Hours', '24/7'),
                const Divider(),
                _buildInfoRow('Manager', 'Robert Johnson'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[600])),
          Text(value, style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPhysicalConfigCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, AppRouter.adminLayoutConfig),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.lightBlue.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.edit_note, color: AppTheme.lightBlue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Physical Configuration', style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold)),
                        Text('120m x 180m x 12m', style: GoogleFonts.lato(fontSize: 11, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  const Icon(Icons.settings_outlined, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSmallStat('Floors', '5'),
                  _buildSmallStat('Docks', '8'),
                  _buildSmallStat('Parking', '45'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.lightBlue)),
        Text(label, style: GoogleFonts.lato(fontSize: 10, color: Colors.grey[500])),
      ],
    );
  }
}
