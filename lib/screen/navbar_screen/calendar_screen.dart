import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:regdogapp/component/upperbar.dart';
import 'package:regdogapp/screen/dog_list.dart';
import 'package:regdogapp/screen/even_calendar.dart/selectevent_screen.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  // ใช้ DateTime ตัวเดียวเก็บค่าวันที่ที่ถูกเลือกเลย
  DateTime _selectedDate = DateTime.now();

  // ข้อมูลตัวอย่างนัดหมาย
  final List<Map<String, dynamic>> _events = [
    {
      'icon': Icons.local_hospital,
      'title': 'นัดตรวจสุขภาพประจำปี',
      'time': '14.00 น.',
      'hasBell': false,
    },
    {
      'icon': Icons.vaccines,
      'title': 'ฉีดวัคซีน',
      'time': '15.00 น.',
      'hasBell': true,
    },
  ];

  String _getMonthName(int month) {
    const months = [
      'มกราคม',
      'กุมภาพันธ์',
      'มีนาคม',
      'เมษายน',
      'พฤษภาคม',
      'มิถุนายน',
      'กรกฎาคม',
      'สิงหาคม',
      'กันยายน',
      'ตุลาคม',
      'พฤศจิกายน',
      'ธันวาคม',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // 🌟 ครอบด้วย SingleChildScrollView ชั้นนอกสุด เผื่อจอมือถือสั้นกว่า 705px จะได้ไม่ Error
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // ยืดเต็มความกว้าง
            children: [
              // ส่วน TopBar
              HomeTopBar(
                showProfile: true,
                onMenuTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DogListPage(),
                    ),
                  );
                },
                onNotificationTap: () => debugPrint("Notification tapped"),
                onProfileTap: () => debugPrint("Profile tapped"),
              ),

              // 🌟 การ์ดสีขาว กว้างเต็มจอ สูง 705px
              Container(
                width: double.infinity,
                height: 705, // ฟิกซ์ความสูงตามที่ต้องการ
                margin: const EdgeInsets.all(0),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                // 🌟 ให้เนื้อหาด้านใน (ปฏิทิน + การ์ดนัดหมาย) เลื่อนได้
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ส่วนปฏิทิน
                      // ส่วนปฏิทิน
                      // 🌟 1. ใช้ SizedBox ครอบและจำกัดความสูง เพื่อตัดพื้นที่ว่างด้านล่างของปฏิทินทิ้ง
                      SizedBox(
                        height:
                            340, // 💡 ถ้าอยากให้ขยับขึ้นอีก ให้ลดตัวเลขนี้ลง (เช่น 320, 330)
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: Theme.of(context).colorScheme.copyWith(
                              primary: const Color(
                                0xFFFFC1CC,
                              ), // สีตอนกดเลือกวัน
                              onPrimary: Colors.black87, // สีตัวหนังสือในวงกลม
                              onSurface:
                                  Colors.black87, // สีตัวหนังสือวันที่ทั่วไป
                            ),
                            textButtonTheme: TextButtonThemeData(
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    Colors.black87, // สีปุ่มสลับปี/เดือน
                              ),
                            ),
                          ),
                          child: CalendarDatePicker(
                            initialDate: _selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            onDateChanged: (DateTime newDate) {
                              setState(() {
                                _selectedDate = newDate;
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'วันที่ ${newDate.day} ${_getMonthName(newDate.month)} ${newDate.year + 543}',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // 🌟 2. ปรับความสูงของเส้นคั่นให้น้อยลง เพื่อให้ติดปฏิทินมากขึ้น
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFEEEEEE),
                      ),
                      const SizedBox(
                        height: 16,
                      ), // ระยะห่างระหว่างเส้นคั่นกับข้อความด้านล่าง
                      // ส่วนข้อความบอกวันที่
                      Text(
                        'วันที่ ${_selectedDate.day} ${_getMonthName(_selectedDate.month)}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ส่วนรายการนัดหมาย
                      ..._events.map((event) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: EventCard(
                            icon: event['icon'] as IconData,
                            title: event['title'] as String,
                            time: event['time'] as String,
                            hasBell: event['hasBell'] as bool,
                            onTap: () {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'ดูรายละเอียด: ${event['title']}',
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      }).toList(),

                      // ปุ่ม + (บวก) สำหรับเพิ่มนัดหมาย
                      Align(
                        alignment: Alignment.centerRight,
                        child: Material(
                          color: const Color(0xFFFEF0B3), // สีเหลืองอ่อน
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EventCategoryPage(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.add,
                                color: Colors.black87,
                                size: 26,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32), // เว้นระยะล่างสุดกันติดขอบ
                    ],
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
// Event Card
// ────────────────────────────────────────────────
class EventCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String time;
  final bool hasBell;
  final VoidCallback? onTap;

  const EventCard({
    super.key,
    required this.icon,
    required this.title,
    required this.time,
    this.hasBell = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F4FF).withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFADD8FF), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFADD8FF),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.blue[800], size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time,
                    style: GoogleFonts.mitr(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            if (hasBell)
              const Icon(
                Icons.notifications_active,
                color: Colors.orange,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
