import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/core/routes/app_router.dart';
import 'package:wms/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:wms/features/auth/data/user_model.dart';
import 'package:wms/core/theme/app_theme.dart';

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
  String? _errorMessage;

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateAndGetError(String email, String password) {
    if (email.isEmpty) {
      return 'Please enter your email address.';
    }
    if (!email.contains('@')) {
      return 'Please enter a valid email address (e.g. name@example.com).';
    }
    if (!_emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address.';
    }
    if (password.isEmpty) {
      return 'Please enter your password.';
    }
    return null;
  }

  String _normalizeServerError(String rawMessage) {
    final lower = rawMessage.toLowerCase();
    if (lower.contains('incorrect') && (lower.contains('email') || lower.contains('password') || lower.contains('mot de passe'))) {
      return 'Incorrect email or password. Please try again.';
    }
    if (lower.contains('disabled') || lower.contains('désactivé') || lower.contains('deactivated')) {
      return 'Your account has been disabled. Please contact your administrator.';
    }
    if (lower.contains('connection') || lower.contains('network') || lower.contains('socket') || lower.contains('failed host lookup')) {
      return 'Unable to connect. Please check your internet and try again.';
    }
    final prefix = 'exception: ';
    if (lower.startsWith(prefix)) {
      return rawMessage.substring(prefix.length).trim();
    }
    return rawMessage;
  }

  void _onLoginPressed(BuildContext context) {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final validationError = _validateAndGetError(email, password);
    if (validationError != null) {
      setState(() => _errorMessage = validationError);
      return;
    }
    setState(() => _errorMessage = null);
    context.read<AuthCubit>().login(email, password);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          // Role-based routing - Clear stack so back button doesn't go to login
          String targetRoute;
          switch (state.user.role) {
            case UserRole.ADMIN:
              targetRoute = AppRouter.adminDashboard;
              break;
            case UserRole.SUPERVISOR:
              targetRoute = AppRouter.supervisorDashboard;
              break;
            case UserRole.EMPLOYEE:
              targetRoute = AppRouter.employeeMain;
              break;
            default:
              targetRoute = AppRouter.landing;
          }
          Navigator.pushNamedAndRemoveUntil(context, targetRoute, (route) => false);
        } else if (state is Unauthenticated && state.message != null && state.message!.isNotEmpty) {
          setState(() => _errorMessage = _normalizeServerError(state.message!));
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Header: dark teal, back + logo
              Container(
                width: double.infinity,
                color: AppTheme.headerTeal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    ),
                    Expanded(
                      child: Center(
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 32,
                          errorBuilder: (_, __, ___) => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'BMS',
                                style: GoogleFonts.lato(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.yellow,
                                ),
                              ),
                              Text(
                                ' ELECTRIC',
                                style: GoogleFonts.lato(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome!',
                        style: GoogleFonts.lato(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.headerTeal,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to your account to continue',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          color: AppTheme.darkGrey,
                        ),
                      ),
                      if (_errorMessage != null && _errorMessage!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildErrorBanner(_errorMessage!),
                      ],
                      const SizedBox(height: 24),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        hint: 'your.email@example.com',
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Enter your password',
                        isPassword: true,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (val) => setState(() => _rememberMe = val ?? false),
                              activeColor: AppTheme.headerTeal,
                              fillColor: WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.selected)) return AppTheme.headerTeal;
                                return Colors.transparent;
                              }),
                              side: BorderSide(color: AppTheme.mediumGrey),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Remember me',
                            style: GoogleFonts.lato(color: AppTheme.darkGrey, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      BlocBuilder<AuthCubit, AuthState>(
                        builder: (context, state) {
                          final isLoading = state is AuthLoading;
                          return SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : () => _onLoginPressed(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.yellow,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: AppTheme.yellow.withOpacity(0.7),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                isLoading ? 'Signing in...' : 'Sign In',
                                style: GoogleFonts.lato(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pushNamed(context, AppRouter.forgotPassword),
                          child: Text(
                            'Forgot Password?',
                            style: GoogleFonts.lato(
                              color: AppTheme.headerTeal,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'Version 1.0.0 Developed by Mobini',
                              style: GoogleFonts.lato(fontSize: 11, color: AppTheme.mediumGrey),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '© 2026 IENE ELEC. All rights reserved.',
                              style: GoogleFonts.lato(fontSize: 11, color: AppTheme.mediumGrey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.errorBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.errorRed.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: AppTheme.errorRed, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.lato(
                color: AppTheme.errorRed,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkGrey,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword && _obscurePassword,
          onChanged: (_) => setState(() => _errorMessage = null),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.lato(color: AppTheme.lightGrey),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.lightGrey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppTheme.lightGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.headerTeal, width: 1.5),
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppTheme.mediumGrey,
                      size: 22,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
