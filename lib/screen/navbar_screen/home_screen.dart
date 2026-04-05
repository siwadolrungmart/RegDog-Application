import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🟢 เพิ่ม import firebase_auth
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:regdogapp/component/upperbar.dart';
import 'package:regdogapp/component/bar.dart';
import 'package:regdogapp/screen/dog_list.dart';
import 'package:regdogapp/screen/register_screen/profile_user_screen.dart';
import 'package:regdogapp/service/dogdatabase_service.dart';
import 'package:regdogapp/providers/current_dog_provider.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key}); // 🟢 ไม่มีการบังคับรับ dogId ตรงนี้แล้ว

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _currentIndex = 2; // หน้าแรกคือ index 2
  final DatabaseService _db = DatabaseService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndLoadCurrentDog();
    });
  }

  Future<void> _checkAndLoadCurrentDog() async {
    final provider = Provider.of<CurrentDogProvider>(context, listen: false);
    // ถ้ายังไม่มีสุนัขที่เลือก
    if (provider.currentDogId == null || provider.currentDogId!.isEmpty) {
      try {
        // 🟢 เปลี่ยนจาก 'temp_user_123' เป็น UID ของผู้ใช้ที่ล็อกอินอยู่จริงๆ
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
            Expanded(
              child: Consumer<CurrentDogProvider>(
                builder: (context, provider, child) {
                  // ถ้าพยายามดึงข้อมูลแล้วแต่ยังไม่มีน้องหมาเลยจริงๆ (Data เป็น null)
                  if (provider.currentDogData == null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("ยังไม่ได้เลือกน้องหมา"),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const DogListPage(),
                                ),
                              );
                            },
                            child: const Text("เลือกน้องหมา"),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  // ถัามีข้อมูลน้องหมาให้แสดงผล
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // รูปสุนัข
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: _buildDogImage(provider.currentDogData?['photoUrl'] ?? provider.currentDogData?['imageUrl']), // เผื่อฟิลด์ใช้ชื่อ photoUrl
                        ),
                        const SizedBox(height: 16),
                        // ชื่อสุนัข
                        Text(
                          provider.dogName,
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // สายพันธุ์
                        Text(
                          provider.currentDogData?['breed'] ?? 'ไม่ระบุสายพันธุ์',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // ข้อมูลเพิ่มเติม
                        _buildInfoRow(
                          'เพศ',
                          provider.currentDogData?['gender'] ?? '-',
                          '',
                        ),
                        _buildInfoRow(
                          'โรคประจำตัว',
                          provider.currentDogData?['diseases'] != null && provider.currentDogData!['diseases'].toString().isNotEmpty 
                              ? provider.currentDogData!['diseases'] 
                              : 'ไม่มี',
                          '',
                        ),
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

  Widget _buildDogImage(String? imageUrl) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey[200],
      ),
      child: imageUrl != null && imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
            )
          : _buildPlaceholderImage(),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey[300],
      ),
      child: const Icon(
        Icons.pets,
        size: 80,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Text(
            unit.isNotEmpty ? '$value $unit' : value,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}