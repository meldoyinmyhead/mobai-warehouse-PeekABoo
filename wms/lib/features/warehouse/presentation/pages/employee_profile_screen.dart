import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms/features/warehouse/presentation/cubits/employee/employee_profile_cubit.dart';

class EmployeeProfileScreen extends StatefulWidget {
  const EmployeeProfileScreen({super.key});

  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen> {
  // Editing controllers
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    context.read<EmployeeProfileCubit>().loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocConsumer<EmployeeProfileCubit, EmployeeProfileState>(
        listener: (context, state) {
          if (state is EmployeeProfileLoaded) {
            _emailController.text = state.email;
            _phoneController.text = state.phone;
          }
        },
        builder: (context, state) {
          if (state is EmployeeProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is EmployeeProfileError) {
            return Center(child: Text(state.message));
          } else if (state is EmployeeProfileLoaded) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Stack(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.person, size: 50, color: Colors.white),
                      ),
                      if (_isEditing)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: CircleAvatar(
                            radius: 15,
                            backgroundColor: Colors.teal,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.camera_alt, size: 15, color: Colors.white),
                              onPressed: () {},
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(state.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal)),
                  Text(state.role, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(state.role, style: const TextStyle(fontSize: 12, color: Colors.grey)), // "Warehouse Operations"

                  const SizedBox(height: 32),
                  _buildSectionTitle('Personal Information'),
                  const SizedBox(height: 16),
                  _buildInfoField('Username', state.name, enabled: false),
                  const SizedBox(height: 16),
                  _buildInfoField('Family Name', state.name.split(' ').last, enabled: false), // Simple logic
                  const SizedBox(height: 16),
                  _buildInfoField('Employee ID', state.employeeId, enabled: false, isGrey: true),
                  const Padding(
                    padding: EdgeInsets.only(left: 12, top: 4),
                    child: Align(alignment: Alignment.centerLeft, child: Text('Employee ID cannot be changed', style: TextStyle(fontSize: 10, color: Colors.grey))),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField('Email', _emailController, enabled: _isEditing),
                  const SizedBox(height: 16),
                  _buildTextField('Phone', _phoneController, enabled: _isEditing),

                  const SizedBox(height: 32),
                  _buildSectionTitle('Work Information'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                         _buildWorkRow('Department:', 'Warehouse Operations'),
                         const SizedBox(height: 8),
                         _buildWorkRow('Role:', state.role),
                         const SizedBox(height: 8),
                         _buildWorkRow('Employee ID:', state.employeeId),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  if (!_isEditing)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() { _isEditing = true; });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Edit Profile'),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() { _isEditing = false; });
                              context.read<EmployeeProfileCubit>().loadProfile(); // Reset
                            },
                             style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              context.read<EmployeeProfileCubit>().updateProfile(
                                email: _emailController.text,
                                phone: _phoneController.text,
                              );
                              setState(() { _isEditing = false; });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Save Changes'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)));
  }

  Widget _buildInfoField(String label, String value, {bool enabled = true, bool isGrey = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: isGrey ? Colors.grey[200] : Colors.grey[50], // Slightly different shade if read-only
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(value, style: const TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool enabled = true}) {
     return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
        ),
      ],
    );
  }

   Widget _buildWorkRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
