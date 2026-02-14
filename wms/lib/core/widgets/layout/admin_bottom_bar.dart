import 'package:flutter/material.dart';
import 'package:wms/core/theme/app_theme.dart';

class AdminBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AdminBottomBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(0, Icons.home_outlined, Icons.home),
          _buildNavItem(1, Icons.group_outlined, Icons.group),
          _buildNavItem(2, Icons.tune_outlined, Icons.tune),
          _buildNavItem(3, Icons.bar_chart_outlined, Icons.bar_chart),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon) {
    final bool isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected ? const Color(0xFF1B2B33) : const Color(0xFF1B2B33).withOpacity(0.6),
          size: 28,
        ),
      ),
    );
  }
}
