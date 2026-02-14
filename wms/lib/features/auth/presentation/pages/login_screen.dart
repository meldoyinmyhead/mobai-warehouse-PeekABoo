import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/core/routes/app_router.dart';
import 'package:wms/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:wms/features/auth/data/user_model.dart';
import 'package:wms/core/theme/app_theme.dart';
import 'package:wms/core/utils/snackbar_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed(BuildContext context) {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      SnackbarUtils.showError(context, 'Veuillez entrer l\'email et le mot de passe');
      return;
    }

    context.read<AuthCubit>().login(email, password);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          // Role-based routing
          switch (state.user.role) {
            case UserRole.ADMIN:
              Navigator.pushReplacementNamed(context, AppRouter.adminDashboard);
              break;
            case UserRole.SUPERVISOR:
              Navigator.pushReplacementNamed(context, AppRouter.supervisorDashboard);
              break;
            case UserRole.EMPLOYEE:
              Navigator.pushReplacementNamed(context, AppRouter.employeeMain);
              break;
          }
        } else if (state is Unauthenticated && state.message != null) {
          SnackbarUtils.showError(context, state.message!);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppTheme.lightBlue, 
          elevation: 0,
          leading: null,
          automaticallyImplyLeading: false,
          title: Row( // Using existing logo logic
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
            Image.asset('assets/images/logo.png', height: 30), 
            ],
          ),
          centerTitle: true,
        ),
        body: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    'Welcome!',
                    style: GoogleFonts.lato(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.lightBlue),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to your account to continue',
                    style: GoogleFonts.lato(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 48),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email Address',
                    hint: 'your.email@example.com',
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'Enter your password',
                    icon: Icons.lock_outline,
                    isPassword: true,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (val) => setState(() => _rememberMe = val!),
                        activeColor: AppTheme.yellow,
                        checkColor: AppTheme.darkBlue,
                      ),
                      Text('Remember me', style: GoogleFonts.lato(color: Colors.grey[700])),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: state is AuthLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: () => _onLoginPressed(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.yellow,
                              foregroundColor: AppTheme.darkBlue,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: Text('Sign In', style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                  ),
                   const SizedBox(height: 16),
                   Center(
                    child: TextButton(
                        onPressed: () {},
                        child: Text('Forgot Password?', style: GoogleFonts.lato(color: AppTheme.lightBlue, fontWeight: FontWeight.bold)),
                      ),
                   ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'Version 1.0.0 Developed by MobAI\n© 2026 BBMS ELEC. All rights reserved.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[700])),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword && _obscurePassword,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.lato(color: Colors.grey[400]),
            prefixIcon: Icon(icon, color: Colors.grey[400]),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey[400]),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  )
                : null,
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00796B)),
            ),
          ),
        ),
      ],
    );
  }
}