import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wms/core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Quick Start Guide',
      'description': 'Here\'s everything you need to know to get started',
      'features': [
        {
          'icon': Icons.person_outline,
          'title': 'Profile & Settings',
          'desc': 'Access your profile, notifications, and app settings from the top navigation bar'
        },
        {
          'icon': Icons.home_outlined,
          'title': 'Home Dashboard',
          'desc': 'View your daily tasks, progress, and recent activities at a glance'
        },
        {
          'icon': Icons.add_circle_outline,
          'title': 'Log a Task',
          'desc': 'Tap the yellow + button to quickly log task completion or updates',
          'highlight': true
        },
        {
          'icon': Icons.description_outlined,
          'title': 'View All Tasks',
          'desc': 'Access your complete task list, organized by category and priority'
        },
        {
          'icon': Icons.flag_outlined,
          'title': 'Flag an Issue',
          'desc': 'Report problems or issues immediately for quick team response and resolution',
          'color': Colors.red
        },
      ]
    },
    // Add more pages if needed, for now using just one tailored page from the design
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBlue,
      body: SafeArea(
        child: Column(
          children: [
             Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/role_selection'),
                  child: Text('Skip', style: GoogleFonts.lato(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (int page) => setState(() => _currentPage = page),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      if (_currentPage > 0) {
                        _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
                      } else {
                         Navigator.pop(context);
                      }
                    },
                    child: Text('Back', style: GoogleFonts.lato(color: Colors.grey[400])),
                  ),
                   Row(
                    children: List.generate(_pages.length, (index) => _buildDot(index)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                         _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
                      } else {
                        Navigator.pushNamed(context, '/role_selection');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.yellow,
                      foregroundColor: AppTheme.darkBlue,
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                       padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: Text('Next', style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            data['title'],
            style: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.darkBlue),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            data['description'],
            style: GoogleFonts.lato(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: (data['features'] as List).length,
              separatorBuilder: (c, i) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final feature = data['features'][index];
                final bool isHighlight = feature['highlight'] ?? false;
                final Color? iconColor = feature['color'];

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isHighlight ? AppTheme.yellow.withOpacity(0.2) : Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        feature['icon'], 
                        color: iconColor ?? (isHighlight ? const Color(0xFFF57F17) : AppTheme.lightBlue),
                        size: 20
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            feature['title'],
                            style: GoogleFonts.lato(
                              fontWeight: FontWeight.bold, 
                              color: iconColor == Colors.red ? Colors.red : (isHighlight ? const Color(0xFFF57F17) : AppTheme.lightBlue),
                              fontSize: 15
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            feature['desc'],
                            style: GoogleFonts.lato(color: Colors.grey[600], fontSize: 13, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
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
        color: _currentPage == index ? AppTheme.yellow : Colors.grey[700],
      ),
    );
  }
}
