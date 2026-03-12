import 'package:flutter/material.dart';
import 'package:regdogapp/component/upperbar.dart';
import 'package:regdogapp/screen/dog_list.dart';
import 'package:regdogapp/screen/even_calendar.dart/playevent_screen.dart';
import 'package:regdogapp/screen/even_calendar.dart/symptomevent_screen.dart';
import 'package:regdogapp/screen/even_calendar.dart/trainevent_screen.dart';
import 'package:regdogapp/screen/even_calendar.dart/vaccinevent_screen.dart';
import 'package:regdogapp/screen/even_calendar.dart/vetvisitevent_screen.dart';
import 'package:regdogapp/screen/even_calendar.dart/walkevent_screen.dart';

// TODO: อย่าลืม Import ไฟล์หน้าเหล่านี้ให้ครบถ้วนนะครับ
// import 'package:regdogapp/screen/add_walk_event_page.dart';
// import 'package:regdogapp/screen/add_play_event_page.dart';
// import 'package:regdogapp/screen/add_train_event_page.dart';
// import 'package:regdogapp/screen/add_symptom_event_page.dart';
// import 'package:regdogapp/screen/add_vaccine_event_page.dart';
// import 'package:regdogapp/screen/add_vet_event_page.dart';

// ────────────────────────────────────────────────
// 1. Main Component: EventCategoryPage
// ────────────────────────────────────────────────
class EventCategoryPage extends StatelessWidget {
  const EventCategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 🌟 1. นำ Scaffold มาครอบไว้ชั้นนอกสุด เพื่อลบเส้นใต้สีเหลืองและตั้งค่าพื้นฐานให้หน้าจอ
    return Scaffold( 
      body: SafeArea(
        child: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // ยืดเต็มความกว้าง
            children: [
              // HomeTopBar ติดขอบบนสุด
              HomeTopBar(
                showProfile: true,
                onMenuTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DogListPage()),
                  );
                },
                onNotificationTap: () => debugPrint("Notification tapped"),
                onProfileTap: () => debugPrint("Profile tapped"),
              ),

              // การ์ดใหญ่ ไม่มี margin บน (ติดกับ TopBar)
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity, // กว้างเต็มหน้าจอ
                    height: 710,
                    margin: const EdgeInsets.fromLTRB(0, 0, 0, 0), // ขอบบน = 0 เพื่อติด TopBar
                    padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header "เลือกประเภทเพื่อบันทึก" + ปุ่มย้อน
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                                onPressed: () {
                                  if (Navigator.canPop(context)) {
                                    Navigator.pop(context);
                                  }
                                },
                              ),
                              const SizedBox(width: 60),
                              const Text(
                                "เลือกประเภทเพื่อบันทึก",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ส่วนเนื้อหาอื่น ๆ (CategorySection ทั้งหมด)
                        // เอา const ออก และเพิ่ม 'page' เข้าไป
                        CategorySection(
                          title: "กิจกรรม",
                          items: const [
                            {'label': 'เดิน', 'icon': Icons.pets, 'page': AddWalkEventPage()},
                            {'label': 'เวลาเล่น', 'icon': Icons.sports_volleyball, 'page': AddPlayEventPage()},
                            {'label': 'ฝึก', 'icon': Icons.assignment, 'page': AddTrainEventPage()},
                          ],
                        ),
                        const SizedBox(height: 24),

                        CategorySection(
                          title: "สุขภาพ",
                          items: const [
                            {'label': 'อาการ', 'icon': Icons.medical_information, 'page': AddSymptomEventPage()},
                            {'label': 'วัคซีน', 'icon': Icons.vaccines, 'page': AddVaccineEventPage()},
                            {'label': 'ยา', 'icon': Icons.medication, 'page': null}, // ยังไม่มีหน้าปลายทาง ให้ใส่ null ไว้ก่อน
                            {'label': 'พบสัตวแพทย์', 'icon': Icons.local_hospital, 'page': AddVetEventPage()},
                          ],
                        ),
                        const SizedBox(height: 24),

                        CategorySection(
                          title: "ค่าใช้จ่าย",
                          items: const [
                            {'label': 'ค่าใช้จ่าย', 'icon': Icons.payments, 'page': null}, // ยังไม่มีหน้าปลายทาง ให้ใส่ null ไว้ก่อน
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────
// 2. Section Component: CategorySection
// ────────────────────────────────────────────────
class CategorySection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;

  const CategorySection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8), 
        
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
                debugPrint('Tapped on ${item['label']}');
                
                // 🌟 ตรวจสอบว่ามีหน้าปลายทางหรือไม่ หากมีให้ทำการเปลี่ยนหน้า
                if (item['page'] != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => item['page'] as Widget,
                    ),
                  );
                } else {
                  // แสดงแจ้งเตือนกรณีที่ยังไม่ได้สร้างหน้า
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('หน้านี้ยังไม่พร้อมใช้งานครับ')),
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

// ────────────────────────────────────────────────
// 3. Button Component: CategoryButton
// ────────────────────────────────────────────────
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
              style: const TextStyle(
                fontSize:   12,
                color: Color(0xFF75A4B2),
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