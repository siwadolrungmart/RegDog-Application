import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:regdogapp/providers/current_dog_provider.dart';
import 'package:regdogapp/screen/register_screen/registerdogname.dart';
import 'package:regdogapp/screen/navbar_screen/home_screen.dart';
import 'package:regdogapp/service/dogdatabase_service.dart';

// ==========================================
// 2. DOG LIST PAGE
// ==========================================
class DogListPage extends StatefulWidget {
  const DogListPage({super.key});

  @override
  State<DogListPage> createState() => _DogListPageState();
}

class _DogListPageState extends State<DogListPage> {
  final DatabaseService _db = DatabaseService();
  
  // สร้างตัวแปรเก็บ uid ปัจจุบัน
  late String _currentUserId;

  @override
  void initState() {
    super.initState();
    // ดึง uid ของผู้ใช้งานปัจจุบันที่กำลังล็อกอินอยู่
    final user = FirebaseAuth.instance.currentUser;
    // ถ้า user ไม่เป็น null ให้เก็บ uid ไว้ (ถ้าเป็น null ให้ใส่ string ว่างกันเหนียวไว้ก่อน)
    _currentUserId = user?.uid ?? ''; 
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: const CustomFAB(),
          body: SafeArea(
            child: Column(
              children: [
                const TopBar(),
               Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _db.getDogsByOwner(_currentUserId), // ใช้ตัวแปรใหม่
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
                        );
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('ไม่พบข้อมูลน้องหมา'));
                      }

                      final docs = snapshot.data!.docs;
                      final mappedDogs = docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final birthTimestamp = data['birthDate'] as Timestamp?;
                        final DateTime? birthDate = birthTimestamp?.toDate();

                        // -----------------------------------------------------
                        // 1. ส่วนคำนวณอายุแบบละเอียด (ปี เดือน วัน)
                        // -----------------------------------------------------
                        String ageStr = 'ไม่ทราบอายุ';
                        if (birthDate != null) {
                          final now = DateTime.now();
                          
                          int years = now.year - birthDate.year;
                          int months = now.month - birthDate.month;
                          int days = now.day - birthDate.day;

                          if (days < 0) {
                            months--;
                            // หาวันสุดท้ายของเดือนก่อนหน้า
                            final previousMonth = DateTime(now.year, now.month, 0);
                            days += previousMonth.day;
                          }

                          if (months < 0) {
                            years--;
                            months += 12;
                          }

                          // ประกอบข้อความอายุ (แสดงเฉพาะหน่วยที่มีค่ามากกว่า 0)
                          List<String> ageParts = [];
                          if (years > 0) ageParts.add('$years ปี');
                          if (months > 0) ageParts.add('$months เดือน');
                          if (days > 0) ageParts.add('$days วัน');
                          
                          // ถ้าอายุน้อยกว่า 1 วัน (เพิ่งเกิดวันนี้)
                          if (ageParts.isEmpty) {
                            ageStr = '0 วัน';
                          } else {
                            ageStr = ageParts.join(' ');
                          }
                        }

                        // -----------------------------------------------------
                        // 2. ส่วนการจัดรูปแบบน้ำหนัก
                        // -----------------------------------------------------
                        final double weightNum =
                            (data['weight'] as num?)?.toDouble() ?? 0.0;
                        final String weightStr = weightNum == 0.0
                            ? '0.0 กิโลกรัม'
                            : '${weightNum.toStringAsFixed(1)} กิโลกรัม';

                        return {
                          'docId': doc.id,
                          'rawData': data, // 🟢 เพิ่มบรรทัดนี้: เก็บข้อมูลดิบส่งให้ Provider
                          'name': (data['name'] ?? 'ไม่ทราบชื่อ').toString(),
                          // -----------------------------------------------------
                          // 3. ปรับ Format วันเกิดเป็น dd MM yyyy (เช่น 23 11 2026)
                          // -----------------------------------------------------
                          'date': birthDate != null
                              ? DateFormat('dd MM yyyy').format(birthDate)
                              : 'ไม่ทราบวันที่',
                          'age': ageStr,
                          'breed': (data['breed'] ?? 'ไม่ทราบพันธุ์').toString(),
                          'weight': weightStr,
                          'image': (data['photoUrl'] ?? '').toString(),
                        };
                      }).toList();

                      return ListView.builder(
                        itemCount: mappedDogs.length,
                        padding: const EdgeInsets.only(top: 10, bottom: 100),
                        itemBuilder: (context, index) {
                          final dog = mappedDogs[index];
                          return DogCard(
                            dogData: dog,
                            docId: dog['docId'] as String,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 3. COMPONENTS
// ==========================================
class CustomFAB extends StatelessWidget {
  const CustomFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Registerdogname()),
        );
      },
      backgroundColor: const Color(0xFFFEF0B3),
      elevation: 4,
      shape: const CircleBorder(),
      child: const Icon(Icons.add, color: Colors.black, size: 28),
    );
  }
}

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Icon(Icons.arrow_back, size: 24, color: Colors.black),
          Row(
            children: [
              Icon(Icons.notifications_none, size: 24, color: Colors.black),
              SizedBox(width: 16),
            ],
          ),
        ],
      ),
    );
  }
}

class DogCard extends StatelessWidget {
  final Map<String, dynamic> dogData;
  final String docId;

  const DogCard({
    super.key,
    required this.dogData,
    required this.docId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            offset: const Offset(0, 3),
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DogCardImage(
            networkImageUrl: dogData['image'] ?? '',
            placeholderAssetPath: 'assets/dog.png',
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dogData['name'] ?? 'ไม่ทราบชื่อ',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                DogInfoItem(
                  icon: Icons.calendar_month_outlined,
                  label: 'วันเกิด:',
                  value: dogData['date'] ?? 'ไม่ทราบ',
                ),
                const SizedBox(height: 2),
                DogInfoItem(
                  icon: Icons.history_toggle_off,
                  label: 'อายุ:',
                  value: dogData['age'] ?? 'ไม่ทราบ',
                ),
                const SizedBox(height: 2),
                DogInfoItem(
                  icon: Icons.pets_outlined,
                  label: 'สายพันธุ์:',
                  value: dogData['breed'] ?? 'ไม่ทราบ',
                ),
                const SizedBox(height: 2),
                DogInfoItem(
                  icon: Icons.scale_outlined,
                  label: 'น้ำหนัก:',
                  value: dogData['weight'] ?? '0.0 กิโลกรัม',
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      final provider = Provider.of<CurrentDogProvider>(
                        context,
                        listen: false,
                      );

                      // 🟢 แก้ไข: ใช้ selectDog แทน selectDogById และส่ง rawData ไปด้วย
                      provider.selectDog(docId, dogData['rawData']);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Homepage(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF0B3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "ต่อไป",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.arrow_forward_outlined,
                            size: 16,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DogCardImage extends StatelessWidget {
  final String networkImageUrl;
  final String placeholderAssetPath;

  const DogCardImage({
    super.key,
    required this.networkImageUrl,
    required this.placeholderAssetPath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 131, // ปรับความกว้างให้พอดีกับ Card
      height: 180, // ปรับความสูงให้สมดุล
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[200], // สีพื้นหลังเผื่อรูปโหลดไม่ขึ้น
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: networkImageUrl.isNotEmpty
            ? Image.network(
                networkImageUrl,
                fit: BoxFit.cover, // ให้รูปเต็มกรอบพอดี ไม่เบี้ยว
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  placeholderAssetPath,
                  fit: BoxFit.cover,
                ),
              )
            : Image.asset(
                placeholderAssetPath,
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}

class DogInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const DogInfoItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black),
          const SizedBox(width: 8),
          Text(
            "$label ",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.black,
              fontWeight: FontWeight.w400,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}