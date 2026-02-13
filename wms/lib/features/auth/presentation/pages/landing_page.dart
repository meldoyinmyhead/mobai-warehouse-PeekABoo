import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/core/theme/app_theme.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBlue,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo/Image placeholder - Using the existing asset but styling might need adjustment or new asset
              // If the design has a specific logo, we might need to swap it. 
              // For now, using the existing one but assuming it looks good on dark or using an Icon as placeholder if needed.
               Image.asset('assets/images/logo_white.png', height: 80, errorBuilder: (c,e,s) => 
                const Icon(Icons.warehouse, size: 80, color: Colors.white)
              ),
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Text('BBMS', style: GoogleFonts.lato(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.yellow)),
                   Text(' ELECTRIC', style: GoogleFonts.lato(fontSize: 32, fontWeight: FontWeight.w300, color: AppTheme.yellow, fontStyle: FontStyle.italic)),
                ],
              ),
              
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
                  onPressed: () => Navigator.pushNamed(context, '/onboarding'), // Navigate to Onboarding
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.yellow,
                    foregroundColor: AppTheme.darkBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 0,
                  ),
                  child: Text('Get Started', style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold)),
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
    );
  }
}