import 'package:flutter/material.dart';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/core/theme/app_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms/features/admin/presentation/cubits/admin_user_cubit.dart';
import 'package:wms/features/auth/data/user_model.dart';

class CreateNewUserScreen extends StatefulWidget {
  const CreateNewUserScreen({super.key});

  @override
  State<CreateNewUserScreen> createState() => _CreateNewUserScreenState();
}

class _CreateNewUserScreenState extends State<CreateNewUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController(text: 'Passjq82ts4e123!');
  UserRole _selectedRole = UserRole.EMPLOYEE;
  bool _sendEmail = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Créer un nouvel utilisateur',
          style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF2C3E50)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined, color: Color(0xFF4A9B9F)),
            onPressed: _submit,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildActionBanner(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildProfileSection(),
                    const SizedBox(height: 16),
                    _buildBasicInfoSection(),
                    const SizedBox(height: 16),
                    _buildRoleSection(),
                    const SizedBox(height: 16),
                    _buildDepartmentSection(),
                    const SizedBox(height: 16),
                    _buildPasswordSection(),
                    const SizedBox(height: 32),
                    _buildActionButtons(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: const Color(0xFFE8F4E8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ajouter un nouveau membre de l\'équipe',
            style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF27AE60)),
          ),
          const SizedBox(height: 4),
          Text(
            'Remplissez les détails de l\'utilisateur et attribuez un rôle',
            style: GoogleFonts.lato(fontSize: 12, color: const Color(0xFF5D6266)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return _buildCardSection(
      title: 'Photo de profil (facultatif)',
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.grey[200],
            child: const Icon(Icons.camera_alt_outlined, color: Colors.grey, size: 30),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF4A9B9F),
                side: const BorderSide(color: Color(0xFF4A9B9F)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text('TÉLÉCHARGER UNE PHOTO'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildCardSection(
      title: 'Informations de base',
      child: Column(
        children: [
          _buildInputField('Prénom *', _firstNameController),
          _buildInputField('Nom de famille *', _lastNameController),
          _buildInputField('ID d\'employé', TextEditingController(text: 'EMP-1TXA49'), enabled: false, hint: 'Généré automatiquement'),
          _buildInputField('E-mail *', _emailController, keyboardType: TextInputType.emailAddress),
          _buildInputField('Phone (optional)', _phoneController, keyboardType: TextInputType.phone, hint: '+1 (555) 000-0000'),
        ],
      ),
    );
  }

  Widget _buildRoleSection() {
    return _buildCardSection(
      title: 'Assign Role *',
      child: Column(
        children: [
          _buildRoleOption(UserRole.EMPLOYEE, 'EMPLOYEE', 'Warehouse worker', const Color(0xFF4A9B9F)),
          const SizedBox(height: 12),
          _buildRoleOption(UserRole.SUPERVISOR, 'SUPERVISOR', 'Team leader', Colors.black87),
          const SizedBox(height: 12),
          _buildRoleOption(UserRole.ADMIN, 'ADMIN', 'System administrator', Colors.orange),
        ],
      ),
    );
  }

  Widget _buildRoleOption(UserRole role, String title, String subtitle, Color color) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F4F8) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF4A9B9F) : Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? const Color(0xFF4A9B9F) : Colors.grey[400]!),
              ),
              child: isSelected ? const Center(child: Icon(Icons.circle, size: 10, color: Color(0xFF4A9B9F))) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
              child: Text(title, style: GoogleFonts.lato(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentSection() {
    return _buildCardSection(
      title: 'Department',
      child: _buildInputField('', TextEditingController()),
    );
  }

  Widget _buildPasswordSection() {
    return _buildCardSection(
      title: 'Password',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              suffixIcon: IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF4A9B9F)),
                onPressed: _generatePassword,
                tooltip: 'Générer un mot de passe',
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mot de passe sécurisé (min 12 chars)',
                style: GoogleFonts.lato(fontSize: 11, color: Colors.grey[500]),
              ),
              TextButton(
                 onPressed: _generatePassword,
                 child: Text(
                   'Générer',
                   style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF4A9B9F)),
                 ),
              )
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [

              Checkbox(
                value: _sendEmail,
                onChanged: (val) => setState(() => _sendEmail = val!),
                activeColor: const Color(0xFF4A9B9F),
              ),
              const Icon(Icons.email_outlined, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Send credentials via email',
                style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006D77),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Create User', style: GoogleFonts.lato(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.grey),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Cancel', style: GoogleFonts.lato(fontSize: 16, color: Colors.grey[700])),
          ),
        ),
      ],
    );
  }

  Widget _buildCardSection({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(title, style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF2C3E50))),
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, {bool enabled = true, String? hint, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            Text(label, style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF2C3E50))),
            const SizedBox(height: 8),
          ],
          TextFormField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              fillColor: enabled ? Colors.white : Colors.grey[100],
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
            ),
            validator: (value) => (label.contains('*') && (value == null || value.isEmpty)) ? 'Requis' : null,
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newUser = UserModel(
        id: '',
        fullName: '${_firstNameController.text} ${_lastNameController.text}',
        email: _emailController.text,
        role: _selectedRole,
        isActive: true,
      );
      context.read<AdminUserCubit>().createUser(newUser, _passwordController.text);
      Navigator.pop(context);
    }
  }

  void _generatePassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%&*';
    final rnd = Random();
    final password = String.fromCharCodes(Iterable.generate(
        12, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
    setState(() {
      _passwordController.text = password;
    });
  }
}
