import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class QrScanResultPage extends StatelessWidget {
  final String dogId;

  const QrScanResultPage({super.key, required this.dogId});

  // ฟังก์ชันโทรออก
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  // ฟังก์ชันคำนวณอายุสุนัข
  String _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return 'ไม่ทราบอายุ';
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
    if (months < 0) { years--; months += 12; }

    List<String> ageParts = [];
    if (years > 0) ageParts.add('$years ปี');
    if (months > 0) ageParts.add('$months เดือน');
    if (days > 0) ageParts.add('$days วัน');

    return ageParts.isEmpty ? 'เกิดวันนี้' : ageParts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    // 🟢 1. ดักจับและตัดเอาเฉพาะ dogId ออกจาก URL ยาวๆ (เผื่อสแกนมาเป็นลิงก์)
    String resolvedDogId = dogId.trim();
    if (resolvedDogId.startsWith('http')) {
      try {
        final uri = Uri.parse(resolvedDogId);
        if (uri.queryParameters.containsKey('dogId')) {
          resolvedDogId = uri.queryParameters['dogId']!;
        } else if (uri.pathSegments.isNotEmpty) {
          resolvedDogId = uri.pathSegments.last;
        }
      } catch (e) {
        debugPrint("Error parsing QR URL: $e");
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F9),
      body: SafeArea(
        child: FutureBuilder<DocumentSnapshot>(
          // ค้นหาด้วย ID ที่ถูกตัดมาแล้ว
          future: FirebaseFirestore.instance.collection('dogs').doc(resolvedDogId).get(),
          builder: (context, snapshot) {
            
            // 1. ระหว่างรอข้อมูล
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // 2. ถ้าไม่พบข้อมูลสุนัข
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(
                child: Text('ไม่พบข้อมูลสุนัข\nรหัส ID: $resolvedDogId',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.mitr(fontSize: 18, color: Colors.grey)),
              );
            }

            // 3. ดึงข้อมูลออกมาใช้งาน
            var dogData = snapshot.data!.data() as Map<String, dynamic>;
            var trackingInfo = dogData['qrTrackingData'] as Map<String, dynamic>? ?? {};

            // ดึงข้อมูลสุนัข (เผื่อกรณีตั้งชื่อ Key ใน Firebase ไว้หลายแบบ)
            String dogName = dogData['name'] ?? dogData['dogName'] ?? 'ไม่ทราบชื่อ';
            String breed = dogData['breed'] ?? 'ไม่ทราบพันธุ์';
            String dogImage = dogData['photoUrl'] ?? dogData['imageUrl'] ?? 'https://via.placeholder.com/150';
            String status = dogData['currentStatus'] ?? 'ปกติ';
            String gender = dogData['gender'] ?? 'ไม่ระบุ';
            String microchip = (dogData['microchip'] ?? 'ไม่มี').toString();
            String diseases = (dogData['diseases'] ?? dogData['disease'] ?? 'ไม่มี').toString();

            // จัดการเรื่องวันเกิดและอายุ
            String dobStr = 'ไม่ระบุ';
            String ageStr = 'ไม่ทราบอายุ';
            var bDate = dogData['birthDate'] ?? dogData['birthday'];
            if (bDate is Timestamp) {
              DateTime birthDate = bDate.toDate();
              dobStr = DateFormat('d MMMM yyyy', 'th').format(birthDate);
              ageStr = _calculateAge(birthDate);
            }

            // ดึงข้อมูลเจ้าของ
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
                  
                  // รูปสุนัข
                  Container(
                    width: 130, height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
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
                  Text(dogName, style: GoogleFonts.mitr(fontSize: 28, fontWeight: FontWeight.bold)),
                  Text(breed, style: GoogleFonts.mitr(fontSize: 16, color: Colors.grey.shade600)),
                  
                  const SizedBox(height: 30),

                  // 🟢 ส่วนนี้คือ "ข้อมูลส่วนตัวสุนัข" ที่หายไปในโค้ดเก่าของคุณ
                  _buildInfoCard("ข้อมูลส่วนตัวสุนัข", [
                    _buildInfoRow(Icons.pets, "เพศ:", gender),
                    _buildInfoRow(Icons.cake, "วันเกิด:", dobStr),
                    _buildInfoRow(Icons.calendar_month, "อายุ:", ageStr),
                    _buildInfoRow(Icons.memory, "ไมโครชิพ:", microchip),
                    _buildInfoRow(Icons.medical_services_outlined, "โรคประจำตัว:", diseases),
                  ]),

                  const SizedBox(height: 20),

                  // ข้อมูลติดต่อเจ้าของ
                  _buildInfoCard("ข้อมูลติดต่อเจ้าของ", [
                    _buildInfoRow(Icons.person, "ชื่อ:", ownerName),
                    _buildInfoRow(Icons.phone, "เบอร์โทร:", ownerPhone),
                    _buildInfoRow(Icons.location_on, "ที่อยู่:", ownerAddress),
                    _buildInfoRow(Icons.info_outline, "หมายเหตุ:", note),
                  ]),
                  
                  const SizedBox(height: 30),
                  
                  // ปุ่มโทรออก (ทำงานได้จริง)
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
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // สร้างกล่องการ์ดสำหรับใส่เนื้อหา
  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.mitr(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF4A7A8C))),
          const Divider(height: 30),
          ...children,
        ],
      ),
    );
  }

  // สร้างบรรทัดข้อมูล
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFFCBE4F0)),
          const SizedBox(width: 10),
          SizedBox(width: 90, child: Text(label, style: GoogleFonts.mitr(color: Colors.grey.shade600, fontSize: 14))),
          Expanded(child: Text(value, style: GoogleFonts.mitr(fontWeight: FontWeight.w500, fontSize: 15))),
        ],
      ),
    );
  }
}