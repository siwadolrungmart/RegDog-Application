import 'package:cloud_firestore/cloud_firestore.dart';
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
  static const String _ownerId = 'temp_user_123';

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
                    stream: _db.getDogsByOwner(_ownerId),
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

                        String ageStr = 'Unknown age';
                        if (birthDate != null) {
                          final now = DateTime.now();
                          final diff = now.difference(birthDate);
                          int totalMonths = (diff.inDays / 30.44).round();
                          int years = totalMonths ~/ 12;
                          int remainingMonths = totalMonths % 12;
                          ageStr = years > 0
                              ? '$years ปี $remainingMonths เดือน'
                              : '$remainingMonths เดือน';
                        }

                        final double weightNum =
                            (data['weight'] as num?)?.toDouble() ?? 0.0;
                        final String weightStr = weightNum == 0.0
                            ? '0.0 กิโลกรัม'
                            : '${weightNum.toStringAsFixed(1)} กิโลกรัม';

                        return {
                          'docId': doc.id,
                          'name': (data['name'] ?? 'Unnamed Dog').toString(),
                          'date': birthDate != null
                              ? DateFormat('dd MMM yyyy').format(birthDate)
                              : 'ไม่ทราบวันที่',
                          'age': ageStr,
                          'breed': (data['breed'] ?? 'ไม่ทราบพันธุ์').toString(),
                          'weight': weightStr,
                          'image': (data['photoUrl'] ?? '').toString(),
                          // ถ้ามี field อื่นใน Firestore ที่อยากใช้ เช่น gender, microchip สามารถเพิ่มได้ที่นี่
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
  final Map<String, dynamic> dogData; // เปลี่ยนเป็น dynamic เพื่อความยืดหยุ่น
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
          DogImage(
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

                 

                    provider.selectDogById(docId);

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

class DogImage extends StatelessWidget {
  final String networkImageUrl;
  final String placeholderAssetPath;

  const DogImage({
    super.key,
    required this.networkImageUrl,
    required this.placeholderAssetPath,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Image.asset(
            placeholderAssetPath,
            width: 131,
            height: 180,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Container(width: 110, height: 110, color: Colors.grey[300]),
          ),
          if (networkImageUrl.isNotEmpty)
            Image.network(
              networkImageUrl,
              width: 131,
              height: 164,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox(width: 131, height: 164);
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const SizedBox(
                  width: 131,
                  height: 164,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
            ),
        ],
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