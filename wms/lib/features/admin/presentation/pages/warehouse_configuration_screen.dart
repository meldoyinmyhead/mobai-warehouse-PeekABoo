import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/core/theme/app_theme.dart';
import 'package:wms/features/admin/presentation/cubits/warehouse_cubit.dart';
import 'package:wms/features/admin/data/models/warehouse_model.dart';
import 'package:wms/core/routes/app_router.dart';

class WarehouseConfigurationScreen extends StatefulWidget {
  const WarehouseConfigurationScreen({super.key});

  @override
  State<WarehouseConfigurationScreen> createState() => _WarehouseConfigurationScreenState();
}

class _WarehouseConfigurationScreenState extends State<WarehouseConfigurationScreen> {
  @override
  void initState() {
    super.initState();
    context.read<WarehouseCubit>().loadWarehouses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Warehouse Configuration',
          style: GoogleFonts.lato(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.lightBlue),
            onPressed: () => Navigator.pushNamed(context, AppRouter.adminCreateWarehouse),
          ),
        ],
      ),
      body: BlocBuilder<WarehouseCubit, WarehouseState>(
        builder: (context, state) {
          if (state is WarehouseLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is WarehouseError) {
            return Center(child: Text(state.message));
          } else if (state is WarehouseLoaded) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manage Warehouses',
                        style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.darkBlue),
                      ),
                      Text(
                        '${state.warehouses.length} warehouses configured',
                        style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.warehouses.length,
                    itemBuilder: (context, index) {
                      final wh = state.warehouses[index];
                      return _buildWarehouseCard(wh);
                    },
                  ),
                ),
              ],
            );
          }
          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRouter.adminCreateWarehouse),
        backgroundColor: AppTheme.yellow,
        child: const Icon(Icons.add, color: AppTheme.darkBlue),
      ),
    );
  }

  Widget _buildWarehouseCard(WarehouseModel wh) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AppRouter.adminWarehouseDetails, arguments: wh);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.veryLightGrey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.warehouse_outlined, color: AppTheme.darkBlue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(wh.name, style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: wh.isActive ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              wh.isActive ? 'ACTIVE' : 'INACTIVE',
                              style: GoogleFonts.lato(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: wh.isActive ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(wh.city, style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoCol('Floors', wh.floors.length.toString()),
                _buildInfoCol('Capacity', '67%'), // Mock capacity for now
                _buildInfoCol('Manager', 'Robert Johnson'), // Mock manager for now
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.lato(fontSize: 10, color: Colors.grey[500])),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }
}
