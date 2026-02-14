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
        backgroundColor: AppTheme.darkBlue,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/logo.png',
                    height: 80,
                    errorBuilder: (c, e, s) =>
                        const Icon(Icons.warehouse, size: 80, color: Colors.white)),
                const SizedBox(height: 24),
                Image.asset("assets/images/logo.png"),
                const SizedBox(height: 120),
                Text(
                  'Powering Warehouse Excellence,',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(fontSize: 18, color: Colors.white70),
                ),
                Text(
                  'One Task at a Time',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(fontSize: 18, color: Colors.white70),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, AppRouter.onboarding),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.yellow,
                      foregroundColor: AppTheme.darkBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 0,
                    ),
                    child: Text('Get Started',
                        style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'Version 1.0.0 Developed by MobAI\n© 2026 BBMS ELEC. All rights reserved.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(fontSize: 10, color: Colors.white30),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}