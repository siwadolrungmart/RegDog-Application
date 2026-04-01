import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; 
import 'package:url_launcher/url_launcher.dart'; 

class QrScanResultPage extends StatelessWidget {
  final String dogId;

  const QrScanResultPage({super.key, required this.dogId});

  // 🟢 ฟังก์ชันคำนวณอายุจากวันเกิด
  String _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int years = now.year - birthDate.year;
    int months = now.month - birthDate.month;
    int days = now.day - birthDate.day;

    if (days < 0) {
      months--;
      days += 30; // กะประมาณ 30 วัน/เดือน
    }
    if (months < 0) {
      years--;
      months += 12;
    }

    if (years > 0) return '$years ปี $months เดือน';
    if (months > 0) return '$months เดือน $days วัน';
    return '$days วัน';
  }

  // 🟢 ฟังก์ชันแปลงวันที่เป็นภาษาไทย (เพิ่มใหม่)
  String _formatThaiDate(DateTime date) {
    const thaiMonths = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];
    int yearTh = date.year + 543; // แปลงเป็น พ.ศ.
    return '${date.day} ${thaiMonths[date.month - 1]} $yearTh';
  }

  // 🟢 ฟังก์ชันโทรออก
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      debugPrint("ไม่สามารถเปิดฟังก์ชันโทรออกได้");
    }
  }

  // 🟢 ฟังก์ชันป้องกัน URL แปลกๆ (กันหน้าจอขาว)
  String _extractSafeDogId(String input) {
    String id = input.trim();
    if (id.contains('dogId=')) {
      id = id.split('dogId=')[1].split('&')[0];
    } else if (id.startsWith('http')) {
      try {
        Uri uri = Uri.parse(id);
        if (uri.pathSegments.isNotEmpty) {
          id = uri.pathSegments.lastWhere((segment) => segment.isNotEmpty, orElse: () => id);
        }
      } catch (_) {}
    }
    return id.replaceAll('/', '').replaceAll('#', '').trim();
  }

  @override
  Widget build(BuildContext context) {
    String resolvedDogId = _extractSafeDogId(dogId);

    return Scaffold(
      // 🟢 นำสีพื้นหลังทิ้งไป เพื่อให้เห็นรูปภาพเต็มที่
      backgroundColor: Colors.transparent,
      body: Container(
        // 🟢 เพิ่มภาพพื้นหลังตามที่ระบุ
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg_watercolor.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: resolvedDogId.isEmpty
              ? Center(
                  child: Text('❌ ลิงก์ไม่ถูกต้อง\n(ไม่พบรหัสสุนัข)',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.mitr(fontSize: 18, color: Colors.grey.shade600)),
                )
              : FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('dogs').doc(resolvedDogId).get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return Center(
                        child: Text('ไม่พบข้อมูลสุนัข\nอาจถูกลบหรือลิงก์ไม่ถูกต้อง',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.mitr(fontSize: 18, color: Colors.grey)),
                      );
                    }

                    var dogData = snapshot.data!.data() as Map<String, dynamic>;
                    var trackingInfo = dogData['qrTrackingData'] as Map<String, dynamic>? ?? {};

                    // 🐶 ดึงข้อมูลพื้นฐาน
                    String dogName = dogData['name'] ?? 'ไม่ทราบชื่อ';
                    String breed = dogData['breed'] ?? 'ไม่ทราบพันธุ์';
                    String dogImage = dogData['photoUrl'] ?? 'https://via.placeholder.com/150';
                    String status = dogData['currentStatus'] ?? 'ปกติ';

                    // 🐶 ดึงข้อมูลสุนัขเชิงลึก
                    String gender = dogData['gender'] ?? 'ไม่ระบุ';
                    
                    // 🟢 จัดการน้ำหนัก
                    String weightStr = 'ไม่ระบุ';
                    if (dogData['weight'] != null && dogData['weight'] > 0) {
                      weightStr = '${dogData['weight']} กก.';
                    }

                    String microchip = (dogData['microchip'] == null || dogData['microchip'].toString().isEmpty) ? 'ไม่มี' : dogData['microchip'];
                    String pedigree = (dogData['pedigree'] == null || dogData['pedigree'].toString().isEmpty) ? 'ไม่มี' : dogData['pedigree'];
                    String diseases = (dogData['diseases'] == null || dogData['diseases'].toString().isEmpty) ? 'ไม่มี' : dogData['diseases'];

                    // 📅 จัดการวันเกิดและอายุ (เรียกใช้ _formatThaiDate)
                    String dobStr = 'ไม่ระบุ';
                    String ageStr = 'ไม่ทราบอายุ';
                    if (dogData['birthDate'] is Timestamp) {
                      DateTime dob = (dogData['birthDate'] as Timestamp).toDate();
                      dobStr = _formatThaiDate(dob); // 🟢 ใช้เดือนภาษาไทยตรงนี้
                      ageStr = _calculateAge(dob);
                    }

                    // 👤 ดึงข้อมูลเจ้าของ
                    String ownerName = trackingInfo['contactName'] ?? 'ไม่ระบุ';
                    String ownerPhone = trackingInfo['phone'] ?? 'ไม่ระบุ';
                    String ownerAddress = trackingInfo['address'] ?? 'ไม่ระบุ';
                    String note = trackingInfo['note'] ?? '-';

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          // ป้ายสถานะ
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: status == 'หาย' ? Colors.red.shade100 : Colors.green.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status == 'หาย' ? '📢 กำลังตามหาสุนัข' : '✅ สถานะ: ปกติ',
                              style: GoogleFonts.mitr(
                                color: status == 'หาย' ? Colors.red.shade800 : Colors.green.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // รูปหมาและชื่อ
                          Container(
                            width: 130, height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle, color: Colors.white,
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                            child: ClipOval(
                              child: Image.network(
                                dogImage, fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => const Icon(Icons.pets, size: 70, color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(dogName, style: GoogleFonts.mitr(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87)),
                          Text(breed, style: GoogleFonts.mitr(fontSize: 16, color: Colors.black54)),
                          
                          const SizedBox(height: 30),

                          // 🟢 ข้อมูลส่วนตัวสุนัข
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95), // ปรับให้โปร่งใสนิดนึงเผื่อให้เข้ากับพื้นหลัง
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("ข้อมูลส่วนตัวสุนัข", style: GoogleFonts.mitr(fontSize: 18, fontWeight: FontWeight.w500, color: const Color(0xFF4A7A8C))),
                                const Divider(height: 30),
                                _buildInfoRow(Icons.pets, "เพศ:", gender),
                                _buildInfoRow(Icons.category, "สายพันธุ์:", breed),
                                _buildInfoRow(Icons.cake, "วันเกิด:", dobStr),
                                _buildInfoRow(Icons.calendar_month, "อายุ:", ageStr),
                                _buildInfoRow(Icons.scale, "น้ำหนัก:", weightStr),
                                _buildInfoRow(Icons.memory, "ไมโครชิพ:", microchip),
                                _buildInfoRow(Icons.description, "ใบเพ็ดดีกรี:", pedigree),
                                _buildInfoRow(Icons.medical_services_outlined, "โรคประจำตัว:", diseases),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ข้อมูลติดต่อเจ้าของ
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("ข้อมูลติดต่อเจ้าของ", style: GoogleFonts.mitr(fontSize: 18, fontWeight: FontWeight.w500, color: const Color(0xFF4A7A8C))),
                                const Divider(height: 30),
                                _buildInfoRow(Icons.person, "ชื่อ:", ownerName),
                                _buildInfoRow(Icons.phone, "เบอร์โทร:", ownerPhone),
                                _buildInfoRow(Icons.location_on, "ที่อยู่:", ownerAddress),
                                const SizedBox(height: 10),
                                _buildInfoRow(Icons.info_outline, "หมายเหตุ:", note),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 30),
                          
                          // 🟢 ปุ่มโทรออก 
                          if (ownerPhone != 'ไม่ระบุ' && ownerPhone.isNotEmpty)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _makePhoneCall(ownerPhone),
                                icon: const Icon(Icons.phone, color: Colors.black87),
                                label: Text("โทรติดต่อเจ้าของ", style: GoogleFonts.mitr(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.w500)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFECA5),
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  elevation: 2,
                                ),
                              ),
                            ),
                          const SizedBox(height: 30), 
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  // Widget ช่วยสร้างแถวข้อมูล
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFFCBE4F0)), 
          const SizedBox(width: 10),
          SizedBox(width: 100, child: Text(label, style: GoogleFonts.mitr(color: Colors.grey.shade600, fontSize: 14))),
          Expanded(child: Text(value, style: GoogleFonts.mitr(fontWeight: FontWeight.w400, fontSize: 15, color: Colors.black87))),
        ],
      ),
    );
  }
}