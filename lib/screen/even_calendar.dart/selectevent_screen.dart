import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:regdogapp/component/upperbar.dart';
import 'package:regdogapp/component/bar.dart'; 
import 'package:regdogapp/screen/dog_list.dart';
import 'package:regdogapp/screen/even_calendar.dart/expense_screen.dart';
import 'package:regdogapp/screen/even_calendar.dart/medicineevent_screen.dart';

// Import หน้าบันทึกต่างๆ 
import 'package:regdogapp/screen/even_calendar.dart/playevent_screen.dart';
import 'package:regdogapp/screen/even_calendar.dart/symptomevent_screen.dart';
import 'package:regdogapp/screen/even_calendar.dart/trainevent_screen.dart';
import 'package:regdogapp/screen/even_calendar.dart/vaccinevent_screen.dart';
import 'package:regdogapp/screen/even_calendar.dart/vetvisitevent_screen.dart';
import 'package:regdogapp/screen/even_calendar.dart/walkevent_screen.dart';
import 'package:regdogapp/screen/register_screen/profile_user_screen.dart';

class EventCategoryPage extends StatefulWidget {
  // รับค่าวันที่เลือกมาจากหน้า Calendar
  final DateTime selectedDate; 
  
  const EventCategoryPage({super.key, required this.selectedDate});

  @override
  State<EventCategoryPage> createState() => _EventCategoryPageState();
}

class _EventCategoryPageState extends State<EventCategoryPage> {
  int _currentIndex = 1; 

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
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HomeTopBar(
      showProfile: true,
      onMenuTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DogListPage()),
        );
      },
  
      onProfileTap: () {
        // 🟢 เปลี่ยนเส้นทางไปหน้า User Profile
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UserProfileScreen()),
        );
      },
    ),

              Container(
                width: double.infinity,
                constraints: const BoxConstraints(
                  minHeight: 690, 
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.all(Radius.circular(15)), 
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black87),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 48), 
                              child: Text(
                                "เลือกประเภทเพื่อบันทึก",
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // --- หมวดหมู่กิจกรรม ---
                    CategorySection(
                      title: "กิจกรรม",
                      titleIcon: Icons.bolt, // 🟢 เปลี่ยนเป็นสายฟ้า สื่อถึงพลังงาน/กิจกรรม
                      iconColor: const Color(0xFF2E86C1), // 🟢 สีน้ำเงิน
                      items: [
                        {
                          'label': 'เดิน', 
                          'icon': Icons.pets, 
                          'page': AddWalkEventPage(selectedDateFromCalendar: widget.selectedDate)
                        },
                        {
                          'label': 'เวลาเล่น', 
                          'icon': Icons.sports_volleyball, 
                          'page': AddPlayEventPage(selectedDateFromCalendar: widget.selectedDate)
                        },
                        {
                          'label': 'ฝึก', 
                          'icon': Icons.assignment, 
                          'page': AddTrainEventPage(selectedDateFromCalendar: widget.selectedDate)
                        },
                      ],
                    ),
                    const SizedBox(height: 15),

                    // --- หมวดหมู่สุขภาพ ---
                    CategorySection(
                      title: "สุขภาพ",
                      titleIcon: Icons.health_and_safety, 
                      iconColor: const Color(0xFF2E86C1), // 🟢 สีน้ำเงิน
                      items: [
                        {
                          'label': 'อาการ', 
                          'icon': Icons.note_alt_outlined, 
                          'page': AddSymptomEventPage(selectedDateFromCalendar: widget.selectedDate)
                        },
                        {
                          'label': 'วัคซีน', 
                          'icon': Icons.vaccines, 
                          'page': AddVaccineEventPage(selectedDateFromCalendar: widget.selectedDate)
                        },
                        {
                          'label': 'ยา', 
                          'icon': Icons.medication, 
                          'page': AddMedicineEventPage(selectedDateFromCalendar: widget.selectedDate)
                        },
                        {
                          'label': 'พบสัตวแพทย์', 
                          'icon': Icons.domain, 
                          'page': AddVetVisitEventPage(selectedDateFromCalendar: widget.selectedDate)
                        },
                      ],
                    ),
                    const SizedBox(height: 15),

                    // --- หมวดหมู่ค่าใช้จ่าย ---
                   // ✅ ถูกต้อง ลบ const ออก
CategorySection(
  title: "ค่าใช้จ่าย",
  titleIcon: Icons.payments, 
  iconColor: const Color(0xFF2E86C1), 
  items: [ // <--- ลบ const ออกไปแล้ว
    {'label': 'ค่าใช้จ่าย', 'icon': Icons.payments, 'page': AddExpenseEventPage(selectedDateFromCalendar: widget.selectedDate)},
  ],
),

                    const SizedBox(height: 25), 
                    const SizedBox(height: 100), 
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CategorySection extends StatelessWidget {
  final String title;
  final IconData titleIcon; 
  final Color iconColor;    
  final List<Map<String, dynamic>> items;

  const CategorySection({
    super.key,
    required this.title,
    required this.titleIcon,
    required this.iconColor,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(titleIcon, color: iconColor, size: 20), // ปรับขนาดไอคอนขึ้นนิดนึงให้สมดุล
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16, 
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12), 
        
        GridView.builder(
          padding: EdgeInsets.zero, 
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.0,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return CategoryButton(
              label: item['label'] as String,
              icon: item['icon'] as IconData,
              onTap: () {
                if (item['page'] != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => item['page'] as Widget),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('หน้านี้ยังไม่พร้อมใช้งานครับ')),
                  );
                }
              },
            );
          },
        ),
      ],
    );
  }
}

class CategoryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const CategoryButton({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE8F4FA),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF75A4B2),
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF75A4B2),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}