import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:regdogapp/component/upperbar.dart';
import 'package:regdogapp/component/bar.dart';
import 'package:regdogapp/screen/dog_list.dart';
import 'package:regdogapp/service/dogdatabase_service.dart'; // อย่าลืม import DatabaseService ของคุณ

class Homepage extends StatefulWidget {
  // รับค่า ID ของสุนัขที่ถูกเลือกมาจากหน้า DogList
  final String dogId; 
  //final String dogName; // รับชื่อมาแสดงก่อนระหว่างรอโหลดข้อมูลได้

  const Homepage({
    super.key, 
    required this.dogId,
    //required this.dogName,
  });

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _currentIndex = 2;
  final DatabaseService _db = DatabaseService(); // เรียกใช้ Service

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
               Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DogListPage(),
      ),
    );
              },
              onNotificationTap: () {
                debugPrint("Notification tapped");
              },
              onProfileTap: () {
                debugPrint("Profile tapped");
              },
            ),

            /// 🔹 เนื้อหาหน้า (แสดงข้อมูลสุนัข)
            Expanded(
              // ใช้ FutureBuilder ดึงข้อมูลสุนัขตาม dogId แบบเรียลไทม์ (หรือใช้ StreamBuilder ก็ได้)
              child: FutureBuilder<DocumentSnapshot>(
                future: _db.getDogById(widget.dogId),
                builder: (context, snapshot) {
                  // ระหว่างรอโหลดข้อมูล
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // ถ้าเกิดข้อผิดพลาด
                  if (snapshot.hasError) {
                    return Center(child: Text("เกิดข้อผิดพลาด: ${snapshot.error}"));
                  }

                  // ถ้าไม่พบข้อมูล
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(child: Text("ไม่พบข้อมูลน้องหมาตัวนี้"));
                  }

                  // ดึงข้อมูลสำเร็จ แปลงเป็น Map
                  var dogData = snapshot.data!.data() as Map<String, dynamic>;

                  // เตรียมข้อมูลเพื่อแสดงผล
                  String breed = dogData['breed'] ?? 'ไม่ระบุสายพันธุ์';
                  String gender = dogData['gender'] ?? 'ไม่ระบุเพศ';
                  double weight = (dogData['weight'] as num?)?.toDouble() ?? 0.0;
                  String photoUrl = dogData['photoUrl'] ?? '';

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // --- 1. รูปภาพสุนัข ---
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: photoUrl.isNotEmpty
                              ? Image.network(
                                  photoUrl,
                                  width: 150,
                                  height: 150,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, err, stack) => _buildPlaceholderImage(),
                                )
                              : _buildPlaceholderImage(),
                        ),
                        const SizedBox(height: 20),

                        // --- 2. ชื่อสุนัข ---
                        //
                        const SizedBox(height: 10),

                        // --- 3. ข้อมูลพื้นฐานแบบ Card ---
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildInfoRow(Icons.pets, "สายพันธุ์", breed),
                              const Divider(),
                              _buildInfoRow(Icons.transgender, "เพศ", gender),
                              const Divider(),
                              _buildInfoRow(Icons.scale, "น้ำหนัก", "$weight กก."),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // TODO: เพิ่มปุ่มดูประวัติน้ำหนัก หรือ กราฟสุขภาพตรงนี้ได้
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget ช่วยสร้างบรรทัดแสดงข้อมูล
  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6B9BA3)),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600]),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  // Widget ช่วยสร้างรูประหว่างรอหรือไม่มีรูป
  Widget _buildPlaceholderImage() {
    return Container(
      width: 150,
      height: 150,
      color: Colors.grey[200],
      child: const Icon(Icons.pets, size: 80, color: Colors.grey),
    );
  }
}