import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:regdogapp/component/bar.dart';

import 'package:regdogapp/component/upperbar.dart';
import 'package:regdogapp/screen/dog_list.dart';
import 'package:regdogapp/screen/register_screen/profile_user_screen.dart';
// TODO: Import ไฟล์ BottomNavBar
// import 'package:regdogapp/component/custom_bottom_nav_bar.dart';

// Import Views ที่เราเพิ่งแยกไฟล์ออกไป
import 'package:regdogapp/screen/summary/expense_view.dart';
import 'package:regdogapp/screen/summary/walk_view.dart';
import 'package:regdogapp/screen/summary/weight_view.dart';

class SummaryPage extends StatefulWidget {
  final bool showBottomBar;

  const SummaryPage({
    super.key, 
    this.showBottomBar = true, 
  });

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  String _selectedTab = 'expense'; 
  int _currentIndex = -1; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     
      bottomNavigationBar: widget.showBottomBar
          ? CustomBottomNavBar( // อย่าลืมแก้ให้ตรงกับชื่อ Class ของคุณ
              selectedIndex: _currentIndex,
              onItemTapped: (index) {
                setState(() => _currentIndex = index);
              },
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            HomeTopBar(
              showProfile: true,
              onMenuTap: () => Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const DogListPage())
              ),
              onProfileTap: () => Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const UserProfileScreen())
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
              child: Text(
                "สรุป",
                style: GoogleFonts.mitr(
                  fontSize: 20,
                  color: const Color(0xFF6DA2B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            _buildTopTabs(),
            Expanded(
              // เรียกใช้งาน Widget ที่แยกไฟล์ไว้ตรงนี้
              child: _buildBodyContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTabButton('ค่าใช้จ่าย', 'expense'),
          _buildTabButton('น้ำหนัก', 'weight'),
          _buildTabButton('เดิน', 'walk'),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, String tabKey) {
    final isSelected = _selectedTab == tabKey;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = tabKey),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFCDE5F7) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.transparent : const Color(0xFFE0E0E0),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: GoogleFonts.mitr(
              color: isSelected ? const Color(0xFF6DA2B8) : Colors.grey.shade500,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_selectedTab == 'expense') return const ExpenseView();
    if (_selectedTab == 'walk') return const WalkView();
    if (_selectedTab == 'weight') return const WeightView();
    return const SizedBox();
  }
}