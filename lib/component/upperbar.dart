import 'package:flutter/material.dart';

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
    this.showProfile = false, // ถ้าต้องการให้มีไอคอนโปรไฟล์ด้านขวาเพิ่ม
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          /// Left - Menu
          IconButton(
            onPressed: onMenuTap,
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