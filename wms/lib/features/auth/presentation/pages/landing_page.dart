import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/core/theme/app_theme.dart';
import 'package:wms/core/routes/app_router.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wms/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:wms/features/auth/data/user_model.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
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
          if (targetRoute != AppRouter.landing) {
            Navigator.pushNamedAndRemoveUntil(context, targetRoute, (route) => false);
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.headerTeal,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              children: [
                // Center content vertically and horizontally: logo, then text, then button
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo: BMS ELECTRIC (centered)
                        Image.asset(
                          'assets/images/logo.png',
                          height: 72,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/images/logo.png',
                            height: 72,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'BMS',
                                  style: GoogleFonts.lato(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.yellow,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  ' ELECTRIC',
                                  style: GoogleFonts.lato(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 80),
                        // Slogan - white, two lines, centered (above the button)
                        Text(
                          'Powering Warehouse Excellence,',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lato(
                            fontSize: 18,
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                        Text(
                          'One Task at a Time',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lato(
                            fontSize: 18,
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Get Started - bright yellow, white text
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pushNamed(context, AppRouter.onboarding),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.yellow,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Get Started',
                              style: GoogleFonts.lato(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Footer pinned to bottom
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      Text(
                        'Version 1.0.0 Developed by Mobini',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lato(
                          fontSize: 11,
                          color: AppTheme.lightGrey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '© 2026 IENE ELEC. All rights reserved.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lato(
                          fontSize: 11,
                          color: AppTheme.lightGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
