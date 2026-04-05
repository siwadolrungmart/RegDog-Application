import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; 
import 'package:url_launcher/url_launcher.dart'; 

class QrScanResultPage extends StatelessWidget {
  final String dogId; // ตัวแปรนี้จะรับค่ามาจากการ Route ใน Web

  const QrScanResultPage({super.key, required this.dogId});

  // 🟢 ฟังก์ชันคำนวณอายุจากวันเกิด
  String _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int years = now.year - birthDate.year;
    int months = now.month - birthDate.month;
    int days = now.day - birthDate.day;

    if (days < 0) {
      months--;
      int prevMonth = now.month == 1 ? 12 : now.month - 1;
      int prevYear = now.month == 1 ? now.year - 1 : now.year;
      days += DateTime(prevYear, prevMonth + 1, 0).day;
    }
    if (months < 0) {
      years--;
      months += 12;
    }

    if (years > 0) return '$years ปี $months เดือน';
    if (months > 0) return '$months เดือน $days วัน';
    return '$days วัน';
  }

  // 🟢 ฟังก์ชันแปลงวันที่เป็นภาษาไทย 
  String _formatThaiDate(DateTime date) {
    const thaiMonths = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];
    int yearTh = date.year + 543; 
    return '${date.day} ${thaiMonths[date.month - 1]} $yearTh';
  }

  // 🟢 ฟังก์ชันโทรออก
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🟢 ดึง Parameters จาก URL โดยใช้ระบบของ Flutter Web โดยตรง
    // ลิงก์: .../scan?dogId=XXX&token=YYY
    final params = Uri.base.queryParameters;
    final String resolvedDogId = params['dogId'] ?? dogId; 
    final String scannedToken = params['token'] ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg_watercolor.png'), // มั่นใจว่ามีไฟล์นี้ในโปรเจกต์ Web
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: resolvedDogId.isEmpty || resolvedDogId == "null"
              ? _buildErrorState('❌ ลิงก์ไม่ถูกต้อง\nไม่พบรหัสสุนัข')
              : FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('dogs').doc(resolvedDogId).get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF4A7A8C)));
                    }

                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return _buildErrorState('ไม่พบข้อมูลสุนัขในระบบ\nอาจถูกลบหรือรหัสไม่ถูกต้อง');
                    }

                    var dogData = snapshot.data!.data() as Map<String, dynamic>;
                    
                    // 🔍 ดึงข้อมูลตามโครงสร้างจริงที่คุณส่งมา
                    String dbToken = dogData['activeQrToken'] ?? ''; 
                    bool isQrActive = dogData['isQrActive'] ?? false;
                    
                    // 1. ตรวจสอบการเปิดใช้งาน
                    if (!isQrActive) {
                      return _buildErrorState('สุนัขตัวนี้ยังไม่ได้เปิดใช้งาน\nระบบคิวอาร์โค้ด');
                    }

                    // 2. 🔥 ตรวจสอบ Security Token (เทียบค่าชั้นนอกสุด)
                    if (dbToken.isNotEmpty && scannedToken != dbToken) {
                      return _buildErrorState('❌ คิวอาร์โค้ดนี้หมดอายุแล้ว\nกรุณาสแกนคิวอาร์โค้ดล่าสุด');
                    }

                    // 🐶 ข้อมูลส่วนตัว
                    String dogName = dogData['name'] ?? 'ไม่ระบุ';
                    String breed = dogData['breed'] ?? 'ไม่ระบุ';
                    String gender = dogData['gender'] ?? 'ไม่ระบุ';
                    String dogImage = (dogData['photoUrl'] != null && dogData['photoUrl'].toString().isNotEmpty) 
                                      ? dogData['photoUrl'] 
                                      : 'https://via.placeholder.com/150';
                    String status = dogData['currentStatus'] ?? 'ปกติ';

                    // 📅 วันเกิดและอายุ
                    String dobStr = 'ไม่ระบุ';
                    String ageStr = 'ไม่ทราบอายุ';
                    if (dogData['birthDate'] is Timestamp) {
                      DateTime dob = (dogData['birthDate'] as Timestamp).toDate();
                      dobStr = _formatThaiDate(dob); 
                      ageStr = _calculateAge(dob);
                    }

                    // 👤 ข้อมูลติดต่อ (ใน qrTrackingData Map)
                    var tracking = dogData['qrTrackingData'] as Map<String, dynamic>? ?? {};
                    String ownerName = tracking['contactName'] ?? 'ไม่ระบุ';
                    String ownerPhone = tracking['phone'] ?? 'ไม่ระบุ';
                    String ownerAddress = tracking['address'] ?? 'ไม่ระบุ';
                    String note = tracking['note'] ?? '-';
                    String weight = (tracking['weight'] != null && tracking['weight'] != 0) 
                                    ? "${tracking['weight']} กก." 
                                    : "ไม่ระบุ";

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          // Badge สถานะ
                          _buildStatusBadge(status),
                          const SizedBox(height: 25),
                          
                          // โปรไฟล์
                          _buildProfileImage(dogImage),
                          const SizedBox(height: 15),
                          Text(dogName, style: GoogleFonts.mitr(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
                          Text(breed, style: GoogleFonts.mitr(fontSize: 18, color: Colors.black54)),
                          
                          const SizedBox(height: 30),

                          // Card ข้อมูลสุนัข
                          _buildDataCard("ข้อมูลส่วนตัวสุนัข", [
                            _infoRow(Icons.pets, "เพศ:", gender),
                            _infoRow(Icons.cake, "วันเกิด:", dobStr),
                            _infoRow(Icons.calendar_month, "อายุ:", ageStr),
                            _infoRow(Icons.scale, "น้ำหนัก:", weight),
                            _infoRow(Icons.memory, "ไมโครชิพ:", dogData['microchip'] ?? 'ไม่มี'),
                            _infoRow(Icons.medical_services_outlined, "โรคประจำตัว:", dogData['diseases'] ?? 'ไม่มี'),
                          ]),

                          const SizedBox(height: 20),

                          // Card ข้อมูลติดต่อ
                          _buildDataCard("ข้อมูลติดต่อเจ้าของ", [
                            _infoRow(Icons.person, "ชื่อ:", ownerName),
                            _infoRow(Icons.phone, "เบอร์โทร:", ownerPhone),
                            _infoRow(Icons.location_on, "ที่อยู่:", ownerAddress),
                            _infoRow(Icons.info_outline, "หมายเหตุ:", note),
                          ]),
                          
                          const SizedBox(height: 30),
                          
                          // ปุ่มโทร
                          if (ownerPhone != 'ไม่ระบุ' && ownerPhone.isNotEmpty)
                            _buildCallButton(ownerPhone),
                          
                          const SizedBox(height: 50),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  // --- UI Components ---

  Widget _buildStatusBadge(String status) {
    bool isLost = status == 'หาย';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: isLost ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: isLost ? Colors.red.shade200 : Colors.green.shade200),
      ),
      child: Text(
        isLost ? '📢 กำลังตามหาสุนัข' : '✅ สถานะ: ปกติ',
        style: GoogleFonts.mitr(color: isLost ? Colors.red.shade700 : Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _buildProfileImage(String url) {
    return Container(
      width: 140, height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
      child: ClipOval(child: Image.network(url, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.pets, size: 80, color: Colors.grey))),
    );
  }

  Widget _buildDataCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.mitr(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF4A7A8C))),
          const Divider(height: 30, thickness: 1),
          ...children
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFFCBE4F0)),
          const SizedBox(width: 12),
          SizedBox(width: 90, child: Text(label, style: GoogleFonts.mitr(color: Colors.black54, fontSize: 14))),
          Expanded(child: Text(value, style: GoogleFonts.mitr(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w400))),
        ],
      ),
    );
  }

  Widget _buildCallButton(String phone) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _makePhoneCall(phone),
        icon: const Icon(Icons.phone_in_talk, color: Colors.black87),
        label: Text("โทรติดต่อเจ้าของ", style: GoogleFonts.mitr(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.w500)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFECA5),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
          elevation: 3,
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, size: 70, color: Colors.grey),
            const SizedBox(height: 20),
            Text(message, textAlign: TextAlign.center, style: GoogleFonts.mitr(fontSize: 18, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}