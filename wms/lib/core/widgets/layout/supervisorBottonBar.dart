import 'package:flutter/material.dart';
import 'package:wms/core/theme/app_theme.dart';

class SupervisorBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const SupervisorBottomBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.map_outlined,
                activeIcon: Icons.map,
                index: 1,
              ),
              _buildNavItem(
                icon: Icons.psychology_outlined ,
                activeIcon: Icons.psychology,
                index: 2,
              ),
              _buildNavItem(
                icon: Icons.flag_outlined,
                activeIcon: Icons.flag,
                index: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required int index,
  }) {
    final isActive = currentIndex == index;
    
    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.lightBlue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isActive ? activeIcon : icon,
          color: isActive ? AppTheme.lightBlue : Colors.grey[600],
          size: 28,
        ),
      ),
    );
  }
}