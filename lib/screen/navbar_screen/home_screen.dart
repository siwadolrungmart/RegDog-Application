import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart'; // 🟢 ใช้ fl_chart

import 'package:regdogapp/component/upperbar.dart';
import 'package:regdogapp/component/bar.dart';
import 'package:regdogapp/screen/dog_list.dart';
import 'package:regdogapp/screen/navbar_screen/calendar_screen.dart';
import 'package:regdogapp/screen/register_screen/profile_user_screen.dart';
import 'package:regdogapp/screen/summary_screen.dart';
import 'package:regdogapp/service/dogdatabase_service.dart';
import 'package:regdogapp/providers/current_dog_provider.dart';

// 🟢 อย่าลืม Import ไฟล์ SummaryPage และ CalendarPage ของคุณ (แก้ไข path ให้ตรงกับโปรเจกต์)
// import 'package:regdogapp/screen/summary_page.dart';
// import 'package:regdogapp/screen/calendar_page.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _currentIndex = 2;
  final DatabaseService _db = DatabaseService();

  DateTime get _startOfWeek {
    DateTime now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1)).copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndLoadCurrentDog();
    });
  }

  Future<void> _checkAndLoadCurrentDog() async {
    final provider = Provider.of<CurrentDogProvider>(context, listen: false);
    if (provider.currentDogId == null || provider.currentDogId!.isEmpty) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final dogs = await _db.getDogsByOwner(user.uid).first;
          if (dogs.docs.isNotEmpty) {
            final firstDoc = dogs.docs.first;
            final data = firstDoc.data() as Map<String, dynamic>;
            provider.selectDog(firstDoc.id, data);
          }
        }
      } catch (e) {
        debugPrint("โหลดสุนัขตัวแรกอัตโนมัติล้มเหลว: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dogProvider = Provider.of<CurrentDogProvider>(context);
    final String? dogId = dogProvider.currentDogId;

    return Scaffold(
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _currentIndex,
        onItemTapped: (index) => setState(() => _currentIndex = index),
      ),
      body: SafeArea(
        child: Column(
          children: [
            HomeTopBar(
              showProfile: true,
              onMenuTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DogListPage())),
              onProfileTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UserProfileScreen())),
            ),
            Expanded(
              child: dogId == null
                  ? _buildNoDogSelected()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildProfileHeader(dogProvider.dogName, dogProvider.currentDogData?['photoUrl']),
                          const SizedBox(height: 5),

                          // 📈 1. กราฟค่าใช้จ่าย
                          // 🟢 เพิ่มการส่งฟังก์ชันไปหน้า SummaryPage
                          _buildSectionHeader("ค่าใช้จ่ายประจำสัปดาห์", () {
                             Navigator.push(context, MaterialPageRoute(builder: (context) => const SummaryPage()));
                          }),
                          const SizedBox(height: 10),
                          _buildRealExpenseChart(dogId), 
                          const SizedBox(height: 15),
                          
                          _buildSectionHeader2("ฟีเจอร์"),
                          const SizedBox(height: 10),
                          _buildFeatureCard(context),
                          const SizedBox(height: 15),
                          
                          // 📅 2. กิจกรรมประจำสัปดาห์
                          // 🟢 เพิ่มการส่งฟังก์ชันไปหน้า CalendarPage
                          _buildSectionHeader("กิจกรรมประจำสัปดาห์", () {
                             Navigator.push(context, MaterialPageRoute(builder: (context) => const CalendarPage()));
                          }),
                          const SizedBox(height: 10),
                          _buildRealWeeklyActivities(dogId),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

// --- 📅 ส่วนดึงข้อมูลกิจกรรมจริง (แบบแบ่งหน้า หน้าละ 4 รายการ) ---
  Widget _buildRealWeeklyActivities(String dogId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('dog_activities')
          .where('dog_id', isEqualTo: dogId)
          .where('start_time', isGreaterThanOrEqualTo: _startOfWeek)
          .orderBy('start_time', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyStateCard("ไม่มีกิจกรรมในสัปดาห์นี้");
        }

        final activities = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['type'] != 'expense';
        }).toList();

        if (activities.isEmpty) {
          return _buildEmptyStateCard("ไม่มีกิจกรรมในสัปดาห์นี้");
        }

        // 🟢 1. แบ่งข้อมูลเป็นชุด ชุดละ 4 รายการ
        final int itemsPerPage = 4;
        List<List<DocumentSnapshot>> pages = [];
        for (var i = 0; i < activities.length; i += itemsPerPage) {
          pages.add(
            activities.sublist(
              i, 
              i + itemsPerPage > activities.length ? activities.length : i + itemsPerPage
            )
          );
        }

        // 🟢 2. สร้าง PageController สำหรับควบคุมการเลื่อนหน้า
        final PageController pageController = PageController();

        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFE1C6FA), width: 1.5), // กรอบสีม่วงอ่อน
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🟢 Header: หัวข้อ "สัปดาห์นี้" และปุ่ม < >
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // แสดงปุ่ม < > เฉพาะเมื่อมีมากกว่า 1 หน้า
                  if (pages.length > 1) 
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            pageController.previousPage(
                              duration: const Duration(milliseconds: 300), 
                              curve: Curves.easeInOut
                            );
                          },
                          child: const Icon(Icons.arrow_back_ios, size: 16, color: Color(0xFF81AAB7)),
                        ),
                        const SizedBox(width: 15),
                        GestureDetector(
                          onTap: () {
                            pageController.nextPage(
                              duration: const Duration(milliseconds: 300), 
                              curve: Curves.easeInOut
                            );
                          },
                          child: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF81AAB7)),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // 🟢 Body: แสดงรายการกิจกรรมครั้งละ 4 รายการ
              SizedBox(
                // กำหนดความสูงให้พอดีกับ 4 รายการ (รายการละประมาณ 50px + margin)
                height: 200, 
                child: PageView.builder(
                  controller: pageController,
                  physics: const BouncingScrollPhysics(), // ทำให้ใช้มือปัดเลื่อนได้ด้วย
                  itemCount: pages.length,
                  itemBuilder: (context, pageIndex) {
                    final pageActivities = pages[pageIndex];
                    
                    return Column(
                      children: pageActivities.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        DateTime startTime = (data['start_time'] as Timestamp).toDate();
                        
                        // สร้างข้อความแสดงเวลา เช่น "12.00 น." หรือ "24/02 12:00"
                        String dateFormatted = DateFormat('dd/MM/yyyy').format(startTime);
                        String timeFormatted = DateFormat('HH:mm').format(startTime); 
                        
                        // 🟢 รวมวันที่และเวลาเข้าด้วยกัน
                        String displayDateTime = "$dateFormatted  $timeFormatted น."; 
                        
                        // ดึงเวลาสิ้นสุดถ้ามี (ถ้ามีการบันทึก duration ไว้)
                        if (data['duration_minutes'] != null && data['duration_minutes'] > 0) {
                          DateTime endTime = startTime.add(Duration(minutes: data['duration_minutes']));
                          String endTimeFormatted = DateFormat('HH:mm').format(endTime);
                          // 🟢 รวมวันที่และเวลา (แบบมีช่วงเวลาสิ้นสุด)
                          displayDateTime = "$dateFormatted  $timeFormatted - $endTimeFormatted น.";
                        }

                        final bool isReminderSet = data['reminder_offset_minutes'] != null;
                        
                        return Container(
                          height: 40, // Fix ความสูงต่อ 1 แถวให้เท่าๆ กัน
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFAEDBFA), width: 1.5), // กรอบสีฟ้าอ่อน
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  data['name'] ?? "กิจกรรม", 
                                  style: GoogleFonts.mitr(fontSize: 14, color: const Color(0xFF81AAB7)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isReminderSet) ...[
                                    const Icon(Icons.notifications_active, size: 14, color: Color(0xFF81AAB7)),
                                    const SizedBox(width: 6),
                                  ],
                                  Text(
                                    displayDateTime, 
                                    style: GoogleFonts.mitr(fontSize: 13, color: const Color(0xFF81AAB7)) // 🟢 ปรับลดขนาด font ลงนิดนึงเผื่อวันที่ยาวเกินไป
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- 📊 ส่วนดึงข้อมูลและวาดกราฟด้วย fl_chart ---
  Widget _buildRealExpenseChart(String dogId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('dog_activities')
          .where('dog_id', isEqualTo: dogId)
          .where('start_time', isGreaterThanOrEqualTo: _startOfWeek)
          .snapshots(),
      builder: (context, snapshot) {
        
        if (snapshot.hasError) {
          debugPrint("Firestore Error: ${snapshot.error}");
          return Container(
            height: 180,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.red.shade200, width: 1.5),
            ),
            child: Text("กราฟไม่แสดงผล\nโปรดดูลิงก์สร้าง Index ใน Debug Console", 
              textAlign: TextAlign.center, 
              style: GoogleFonts.mitr(color: Colors.red, fontSize: 12)
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 180, 
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFD6C8EF), width: 1.5),
            ),
            child: const Center(child: CircularProgressIndicator(color: Color(0xFFE1C6FA)))
          );
        }

        Map<int, double> dailyTotals = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};

        if (snapshot.hasData && snapshot.data != null) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            
            if (data['type'] == 'expense' && data['cost'] != null && data['start_time'] != null) {
              DateTime date = (data['start_time'] as Timestamp).toDate();
              
              double amount = 0.0;
              if (data['cost'] is num) {
                amount = (data['cost'] as num).toDouble();
              } else if (data['cost'] is String) {
                amount = double.tryParse(data['cost']) ?? 0.0;
              }
              
              dailyTotals[date.weekday] = (dailyTotals[date.weekday] ?? 0) + amount;
            }
          }
        }

        double maxTotal = dailyTotals.values.reduce(max);
        double maxY = maxTotal > 0 ? maxTotal * 1.3 : 5000; 

        return Container(
          padding: const EdgeInsets.only(top: 25, bottom: 10, left: 10, right: 10),
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFD6C8EF), width: 1.5),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              minY: 0, 
              barTouchData: BarTouchData(enabled: false), 
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const days = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'];
                      int index = value.toInt() - 1;
                      if (index >= 0 && index < days.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(days[index], style: GoogleFonts.mitr(fontSize: 11, color: Colors.grey)),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    reservedSize: 28,
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      double total = dailyTotals[value.toInt()] ?? 0;
                      if (total <= 0) return const SizedBox.shrink();
                      
                      List<Color> colors = [
                        const Color(0xFFFCE18D), const Color(0xFFF9A8D4), const Color(0xFFC6F68D),
                        const Color(0xFFFDBA8C), const Color(0xFFAEDBFA), const Color(0xFFE1C6FA), const Color(0xFFFA8B8B)
                      ];
                      Color color = colors[value.toInt() - 1];
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          "${(total / 1000).toStringAsFixed(1)}k", 
                          style: GoogleFonts.mitr(fontSize: 10, color: color)
                        ),
                      );
                    },
                    reservedSize: 22,
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: [
                _buildFlBarGroup(1, dailyTotals[1]!, const Color(0xFFFCE18D), maxY),
                _buildFlBarGroup(2, dailyTotals[2]!, const Color(0xFFF9A8D4), maxY),
                _buildFlBarGroup(3, dailyTotals[3]!, const Color(0xFFC6F68D), maxY),
                _buildFlBarGroup(4, dailyTotals[4]!, const Color(0xFFFDBA8C), maxY),
                _buildFlBarGroup(5, dailyTotals[5]!, const Color(0xFFAEDBFA), maxY),
                _buildFlBarGroup(6, dailyTotals[6]!, const Color(0xFFE1C6FA), maxY),
                _buildFlBarGroup(7, dailyTotals[7]!, const Color(0xFFFA8B8B), maxY),
              ],
            ),
          ),
        );
      },
    );
  }

  BarChartGroupData _buildFlBarGroup(int x, double y, Color color, double maxY) {
    double barHeight = y > 0 ? y : (maxY * 0.01); 
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: barHeight, 
          color: color,
          width: 25,
          borderRadius: BorderRadius.circular(5),
          backDrawRodData: BackgroundBarChartRodData(show: false),
        ),
      ],
    );
  }

  // --- 🛠️ UI Helpers พื้นฐานอื่นๆ ---

  Widget _buildEmptyStateCard(String message) {
    return Container(
      height: 100,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
      child: Center(child: Text(message, style: GoogleFonts.mitr(color: Colors.grey))),
    );
  }

  Widget _buildNoDogSelected() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.pets, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text("ยังไม่ได้เลือกน้องหมา", style: GoogleFonts.mitr()),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DogListPage())), 
            child: const Text("เลือกน้องหมา")
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(String name, String? imageUrl) {
    return Column(
      children: [
        Container(
          width: 120, height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
            color: Colors.grey[200],
            image: (imageUrl != null && imageUrl.isNotEmpty) ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) : null,
          ),
          child: (imageUrl == null || imageUrl.isEmpty) ? const Icon(Icons.pets, size: 60, color: Colors.grey) : null,
        ),
        const SizedBox(height: 5),
        Text(name, style: GoogleFonts.mitr(fontSize: 26, color: const Color(0xFF6DA2B8))),
      ],
    );
  }

  // 🟢 แก้ไขรับค่า onTap เพื่อให้กดไปหน้าอื่นได้
  Widget _buildSectionHeader(String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0), // เพิ่ม padding เล็กน้อยให้ขอบตรงกัน
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
        children: [
          _buildSectionTitle(title),
          GestureDetector(
            onTap: onTap,
            child: Text("ดูทั้งหมด >", style: GoogleFonts.mitr(fontSize: 12, color: const Color(0xFF6DA2B8))),
          ),
        ]
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(title, style: GoogleFonts.mitr(fontSize: 16, fontWeight: FontWeight.w500));

  // 🟢 ใส่ GestureDetector เพื่อให้ปุ่มสรุปตรงกลางกดได้
  Widget _buildFeatureCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const SummaryPage()));
      },
      child: Container(
        padding: const EdgeInsets.all(5),
        margin: const EdgeInsets.symmetric(horizontal: 15), // ปรับขอบให้ตรงกับเนื้อหา
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade200)),
        child: Column(children: [
          const Icon(Icons.bar_chart, size: 40, color: Color(0xFF6DA2B8)), // เปลี่ยนเป็น Icon ธรรมดาเพื่อป้องกันการกดซ้อนกับ IconButton
          Text("สรุป", style: GoogleFonts.mitr(color: const Color(0xFF6DA2B8)))
        ]),
      ),
    );
  }
  
  // 🟢 เอาปุ่ม ดูทั้งหมด > ออกจากส่วนฟีเจอร์แล้ว
  Widget _buildSectionHeader2(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start, 
      children: [
        _buildSectionTitle(title),
      ]
    );
  }

  Widget _buildSectionTitle2(String title) => Text(title, style: GoogleFonts.mitr(fontSize: 16, fontWeight: FontWeight.w500));
}