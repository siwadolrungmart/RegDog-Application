import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';                    // ← เพิ่ม
import 'package:regdogapp/component/upperbar.dart';
import 'package:regdogapp/component/bar.dart';
import 'package:regdogapp/screen/dog_list.dart';
import 'package:regdogapp/service/dogdatabase_service.dart';
import 'package:regdogapp/providers/current_dog_provider.dart'; // ← เพิ่ม (ปรับ path ให้ตรงกับโปรเจกต์คุณ)

class Homepage extends StatefulWidget {
  // ยังคงรับ dogId ไว้เพื่อความยืดหยุ่น (จาก DogList)
  final String dogId;

  const Homepage({
    super.key,
    required this.dogId,
  });

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _currentIndex = 2;
  final DatabaseService _db = DatabaseService();

  @override
  void initState() {
    super.initState();
    // โหลดข้อมูลครั้งเดียวแล้วเก็บใน Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAndSelectDog();
    });
  }

  Future<void> _loadAndSelectDog() async {
    final provider = Provider.of<CurrentDogProvider>(context, listen: false);

    // ถ้ายังไม่มีข้อมูล หรือเป็นสุนัขตัวอื่น → โหลดใหม่
    if (provider.currentDogId != widget.dogId) {
      try {
        final DocumentSnapshot doc = await _db.getDogById(widget.dogId);
        if (doc.exists) {
          final dogData = doc.data() as Map<String, dynamic>;
          provider.selectDog(widget.dogId, dogData);
        }
      } catch (e) {
        debugPrint("โหลดข้อมูลสุนัขล้มเหลว: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _currentIndex,
        onItemTapped: (index) {
          setState(() => _currentIndex = index);
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
                  MaterialPageRoute(builder: (context) => const DogListPage()),
                );
              },
              onNotificationTap: () => debugPrint("Notification tapped"),
              onProfileTap: () => debugPrint("Profile tapped"),
            ),

            /// 🔹 เนื้อหาหน้า — ใช้ Provider แทน FutureBuilder
            Expanded(
              child: Consumer<CurrentDogProvider>(
                builder: (context, provider, child) {
                  // ระหว่างโหลดข้อมูล (หรือยังไม่มีข้อมูล)
                  if (provider.currentDogData == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // --- 1. รูปภาพสุนัข ---
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: provider.dogImage.isNotEmpty
                              ? Image.network(
                                  provider.dogImage,
                                  width: 180,
                                  height: 180,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, err, stack) =>
                                      _buildPlaceholderImage(),
                                )
                              : _buildPlaceholderImage(),
                        ),
                        const SizedBox(height: 16),

                        // --- 2. ชื่อสุนัข (เพิ่มให้เด่น) ---
                        Text(
                          provider.dogName,
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          provider.dogBreed,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // --- 3. การ์ดข้อมูลพื้นฐาน (ใช้ getter จาก Provider) ---
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                         
                        ),

                        const SizedBox(height: 30),
                        // TODO: เพิ่มปุ่มดูประวัติ, กราฟน้ำหนัก, วัคซีน ฯลฯ
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

  // Widget ช่วยสร้างบรรทัดแสดงข้อมูล (ปรับให้สวยขึ้นเล็กน้อย)
  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6B9BA3), size: 26),
          const SizedBox(width: 16),
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[700]),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Placeholder รูปภาพ
  Widget _buildPlaceholderImage() {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(Icons.pets, size: 90, color: Colors.grey),
    );
  }
}