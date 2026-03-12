import 'package:flutter/material.dart';
// ✅ 1. อย่าลืม Import ไฟล์หน้า DogListPage (แก้ path ให้ตรงกับโปรเจกต์คุณ)
import 'package:regdogapp/screen/dog_list.dart'; 

class HomeTopBar extends StatelessWidget {
  final VoidCallback? onMenuTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final bool showProfile;

  const HomeTopBar({
    super.key,
    this.onMenuTap,
    this.onNotificationTap,
    this.onProfileTap,
    this.showProfile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          /// Left - Menu
          IconButton(
            // ✅ 2. แก้ไขตรง onPressed ให้สั่ง Navigator โดยตรง
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DogListPage(),
                ),
              );
              
              // หากยังต้องการให้โค้ดภายนอกทำงานด้วย (ถ้ามี) ก็ใส่บรรทัดนี้เพิ่ม
              if (onMenuTap != null) onMenuTap!();
            },
            icon: const Icon(
              Icons.menu,
              size: 24,
            ),
          ),

          /// Right - Notification (+ optional profile)
          Row(
            children: [
              IconButton(
                onPressed: onNotificationTap,
                icon: const Icon(
                  Icons.notifications_none,
                  size: 24,
                ),
              ),
              if (showProfile)
                IconButton(
                  onPressed: onProfileTap,
                  icon: const Icon(
                    Icons.person_outline,
                    size: 24,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}