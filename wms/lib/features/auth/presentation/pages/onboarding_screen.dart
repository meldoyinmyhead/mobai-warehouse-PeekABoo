import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/core/theme/app_theme.dart';
import 'package:wms/core/routes/app_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<Map<String, dynamic>> _quickStartItems = [
    {
      'icon': Icons.add_circle_outline,
      'title': 'Log a Task',
      'desc': 'Tap the yellow + button to quickly log task completion or updates',
      'color': AppTheme.yellow,
    },
    {
      'icon': Icons.description_outlined,
      'title': 'View All Tasks',
      'desc': 'Access your complete task list organized by category and priority',
      'color': AppTheme.lightBlue,
    },
    {
      'icon': Icons.flag_outlined,
      'title': 'Flag an Issue',
      'desc': 'Report problems or issues immediately for quick team response and resolution',
      'color': AppTheme.red,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.veryLightGrey,
      body: SafeArea(
        child: Column(
          children: [
            // Skip - top right, teal text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, AppRouter.roleSelection),
                  child: Text(
                    'Skip',
                    style: GoogleFonts.lato(
                      color: AppTheme.lightBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (int page) => setState(() => _currentPage = page),
                children: [
                  _buildIntroPage(),
                  _buildQuickStartPage(),
                ],
              ),
            ),
            // Bottom: dots + Back / Next
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(2, (i) => _buildDot(i)),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      // Back
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            if (_currentPage > 0) {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              Navigator.pop(context);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.darkGrey,
                            side: const BorderSide(color: AppTheme.darkGrey),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text('Back', style: GoogleFonts.lato(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Next
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_currentPage < 1) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              Navigator.pushNamed(context, AppRouter.roleSelection);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.lightBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Next',
                            style: GoogleFonts.lato(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
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
    );
  }

  Widget _buildIntroPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Landing / warehouse illustration from assets (with background so transparent PNG is visible)
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.lightBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/landing_image.png',
                height: 220,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.warehouse, size: 80, color: AppTheme.lightBlue),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Title: EBMS (yellow) + Dedicated (dark grey) + Warehouse Manager App (teal)
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'EBMS ',
                  style: GoogleFonts.lato(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.yellow,
                  ),
                ),
                TextSpan(
                  text: 'Dedicated\n',
                  style: GoogleFonts.lato(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGrey,
                  ),
                ),
                TextSpan(
                  text: 'Warehouse Manager App',
                  style: GoogleFonts.lato(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.lightBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your comprehensive warehouse management solution for inventory, tasks, and team collaboration.',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 14,
              color: AppTheme.darkGrey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStartPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            'Quick Start Guide',
            style: GoogleFonts.lato(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkGrey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Here\'s everything you need to know to get started',
            textAlign: TextAlign.center,
            style: GoogleFonts.lato(
              fontSize: 14,
              color: AppTheme.darkGrey,
            ),
          ),
          const SizedBox(height: 28),
          // 3 items only
          ..._quickStartItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildFeatureCard(
                  icon: item['icon'] as IconData,
                  title: item['title'] as String,
                  desc: item['desc'] as String,
                  color: item['color'] as Color,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    color: AppTheme.darkGrey,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _currentPage == index ? AppTheme.lightBlue : AppTheme.lightGrey,
      ),
    );
  }
}
