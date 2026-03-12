import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 35),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFC0E4F6),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(icon: Icons.qr_code, label: 'คิวอาร์โค้ด', index: 0, isActive: selectedIndex == 0),
          _buildNavItem(icon: Icons.calendar_today_outlined, label: 'ปฏิทิน', index: 1, isActive: selectedIndex == 1),
          _buildNavItem(icon: Icons.home_outlined, label: 'หน้าแรก', index: 2, isActive: selectedIndex == 2),
          _buildNavItem(icon: Icons.location_on_outlined, label: 'สถานที่', index: 3, isActive: selectedIndex == 3),
          _buildNavItem(icon: Icons.pets_outlined, label: 'โปรไฟล์', index: 4, isActive: selectedIndex == 4),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () => onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: isActive
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFFECA5) : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: isActive
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.black, size: 22),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.black87, size: 22),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.w400),
                  ),
                ],
              ),
      ),
    );
  }
}