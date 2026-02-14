import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/core/theme/app_theme.dart';
import 'package:wms/features/admin/data/models/warehouse_model.dart';
import 'package:wms/features/admin/presentation/cubits/warehouse_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateWarehouseScreen extends StatefulWidget {
  const CreateWarehouseScreen({super.key});

  @override
  State<CreateWarehouseScreen> createState() => _CreateWarehouseScreenState();
}

class _CreateWarehouseScreenState extends State<CreateWarehouseScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Basic Info
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _hoursController = TextEditingController();
  final _managerController = TextEditingController();

  // Dimensions
  final _widthController = TextEditingController(text: '0');
  final _lengthController = TextEditingController(text: '0');
  final _heightController = TextEditingController(text: '0');

  // Capacity
  final _floorsController = TextEditingController(text: '1');
  final _capacityController = TextEditingController(text: '1000');

  // Facilities
  final _docksController = TextEditingController(text: '0');
  final _parkingController = TextEditingController(text: '0');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Warehouse',
          style: GoogleFonts.lato(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Basic Information', Icons.business_outlined),
              const SizedBox(height: 16),
              _buildTextField('Warehouse Name *', _nameController, hint: 'Enter warehouse name'),
              _buildTextField('Address *', _addressController, hint: 'Enter full address'),
              Row(
                children: [
                  Expanded(child: _buildTextField('City *', _cityController, hint: 'City')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('Operating Hours', _hoursController, hint: '24/7')),
                ],
              ),
              _buildTextField('Manager Name', _managerController, hint: 'Enter manager name'),
              
              const SizedBox(height: 32),
              _buildSectionHeader('Dimensions', Icons.straighten_outlined),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField('Width (m) *', _widthController, isNumber: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('Length (m) *', _lengthController, isNumber: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('Height (m) *', _heightController, isNumber: true)),
                ],
              ),

              const SizedBox(height: 32),
              _buildSectionHeader('Floors & Capacity', Icons.layers_outlined),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField('Number of Floors *', _floorsController, isNumber: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('Max Weight/Item', _capacityController, isNumber: true)),
                ],
              ),

              const SizedBox(height: 32),
              _buildSectionHeader('Facilities', Icons.warehouse_outlined),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField('Loading Docks *', _docksController, isNumber: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('Parking Spaces *', _parkingController, isNumber: true)),
                ],
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.yellow,
                    foregroundColor: AppTheme.darkBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text('Create Warehouse', style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.lato(color: Colors.grey[600], fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.lightBlue),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkBlue),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {String? hint, bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            style: GoogleFonts.lato(fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.lato(color: Colors.grey[400], fontSize: 14),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.lightBlue)),
            ),
            validator: (value) {
              if (label.contains('*') && (value == null || value.isEmpty)) {
                return 'This field is required';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final warehouse = WarehouseModel(
        id: '', // Backend will generate
        code: 'WH-${_nameController.text.toUpperCase().replaceAll(' ', '_')}',
        name: _nameController.text,
        address: _addressController.text,
        city: _cityController.text,
        openingHours: _hoursController.text,
        width: double.tryParse(_widthController.text) ?? 0.0,
        length: double.tryParse(_lengthController.text) ?? 0.0,
        height: double.tryParse(_heightController.text) ?? 0.0,
        isActive: true,
      );
      
      context.read<WarehouseCubit>().createWarehouse(warehouse);
      Navigator.pop(context);
    }
  }
}
