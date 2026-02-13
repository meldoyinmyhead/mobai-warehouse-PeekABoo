import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.inventory_2_outlined, size: 120, color: Color(0xFF00796B)),
              const SizedBox(height: 40),
              Text(
                'Welcome to BBMS Electric',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF004D40)),
              ),
              const SizedBox(height: 16),
              Text(
                'Your comprehensive warehouse management solution for inventory, tasks, and team collaboration.',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 60),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD600),
                    foregroundColor: const Color(0xFF004D40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Sign In', style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Version 1.0.0 Developed by MobAI\n© 2026 BBMS ELEC. All rights reserved.',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(fontSize: 12, color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
