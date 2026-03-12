import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:regdogapp/component/upperbar.dart';
import 'package:regdogapp/component/bar.dart';
import 'package:regdogapp/screen/dog_list.dart';
import 'package:regdogapp/service/dogdatabase_service.dart';
import 'package:regdogapp/providers/current_dog_provider.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _currentIndex = 2;
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
        final dogs = await _db.getDogsByOwner('temp_user_123').first;
        if (dogs.docs.isNotEmpty) {
          final firstDoc = dogs.docs.first;
          final data = firstDoc.data() as Map<String, dynamic>;
          provider.selectDog(firstDoc.id, data);
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
              onNotificationTap: () => debugPrint("Notification tapped"),
              onProfileTap: () => debugPrint("Profile tapped"),
            ),
            Expanded(
              child: Consumer<CurrentDogProvider>(
                builder: (context, provider, child) {
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
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // รูปสุนัข
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: _buildDogImage(provider.currentDogData?['imageUrl']),
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
                        // ข้อมูลเพิ่มเติม (เช่น อายุ, เพศ, น้ำหนัก)
                        _buildInfoRow(
                          'อายุ',
                          provider.currentDogData?['age']?.toString() ?? '-',
                          'ปี',
                        ),
                        _buildInfoRow(
                          'เพศ',
                          provider.currentDogData?['gender'] ?? '-',
                          '',
                        ),
                        _buildInfoRow(
                          'น้ำหนัก',
                          provider.currentDogData?['weight']?.toString() ?? '-',
                          'กก.',
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
            '$value $unit',
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