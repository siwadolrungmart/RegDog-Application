import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:regdogapp/providers/current_dog_provider.dart';

// Import หน้าต่างๆ ของคุณ
import 'package:regdogapp/screen/navbar_screen/calendar_screen.dart';
import 'package:regdogapp/screen/navbar_screen/dogprofile_screen.dart';
import 'package:regdogapp/screen/navbar_screen/home_screen.dart';
import 'package:regdogapp/screen/navbar_screen/places_screen.dart';
import 'package:regdogapp/screen/navbar_screen/qr_screen.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  void _navigate(BuildContext context, int index) {
    if (index == selectedIndex) return;

    final provider = Provider.of<CurrentDogProvider>(context, listen: false);
    final String currentDogId = provider.currentDogId ?? ''; 

    Widget page;
    switch (index) {
      case 0:
        page = const QrCodePage(); 
        break;
      case 1:
        page = CalendarPage(); 
        break;
      case 2:
        page = const Homepage();
        break;
      case 3:
        page = const PlacePage(); 
        break;
      case 4:
        page = const DogProfilePage(); 
        break;
      // 🟢 เพิ่ม default แบบให้ return ออกไปเลย (ไม่ต้องทำอะไรถ้าเป็นค่าที่ไม่ได้กำหนด)
      default:
        return; 
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

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
          _buildNavItem(context, icon: Icons.qr_code, label: 'คิวอาร์โค้ด', index: 0, isActive: selectedIndex == 0),
          _buildNavItem(context, icon: Icons.calendar_today_outlined, label: 'ปฏิทิน', index: 1, isActive: selectedIndex == 1),
          _buildNavItem(context, icon: Icons.home_outlined, label: 'หน้าแรก', index: 2, isActive: selectedIndex == 2),
          _buildNavItem(context, icon: Icons.location_on_outlined, label: 'สถานที่', index: 3, isActive: selectedIndex == 3),
          _buildNavItem(context, icon: Icons.pets_outlined, label: 'โปรไฟล์', index: 4, isActive: selectedIndex == 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int index,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () {
        onItemTapped(index); 
        _navigate(context, index); 
      },
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