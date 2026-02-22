import 'package:flutter/material.dart';
import 'package:regdogapp/component/upperbar.dart';
import 'package:regdogapp/component/bar.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _currentIndex = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _currentIndex,
        onItemTapped: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            /// 🔹 Top Bar Component
            HomeTopBar(
              showProfile: true,
              onMenuTap: () {
                debugPrint("Menu tapped");
              },
              onNotificationTap: () {
                debugPrint("Notification tapped");
              },
              onProfileTap: () {
                debugPrint("Profile tapped");
              },
            ),

            /// 🔹 เนื้อหาหน้า
            const Expanded(
              child: Center(
                child: Text(
                  "Home Page Content",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}