import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/core/theme/app_theme.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/landing_image.png', width: MediaQuery.of(context).size.width, height: 200),
              const SizedBox(height: 40),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('EBMS', textAlign: TextAlign.center, style: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.yellow)),
                    Text(
                      ' Dédié',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ],
                ),
              ),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Gestionnaire d\'Entrepôt', textAlign: TextAlign.center, style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.darkBlue)),
                    Text(
                      ' App',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Votre solution complète de gestion d\'entrepôt pour l\'inventaire, les tâches et la collaboration d\'équipe.',
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
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Se Connecter', style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Version 1.0.0 Développé par MobAI\n© 2026 BBMS ELEC. Tous droits réservés.',
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