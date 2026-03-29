import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QrScanResultPage extends StatelessWidget {
  final String dogId; // รับค่า ID มาจาก URL

  const QrScanResultPage({super.key, required this.dogId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F9), // สีพื้นหลังแบบในรูป
      body: SafeArea(
        child: FutureBuilder<DocumentSnapshot>(
          // ดึงข้อมูลหมาจาก Firestore แบบเรียลไทม์
          future: FirebaseFirestore.instance.collection('dogs').doc(dogId).get(),
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

            // ดึงข้อมูลมาใช้งาน
            var dogData = snapshot.data!.data() as Map<String, dynamic>;
            var trackingInfo = dogData['qrTrackingData'] as Map<String, dynamic>? ?? {};

            String dogName = dogData['name'] ?? 'ไม่ทราบชื่อ';
            String breed = dogData['breed'] ?? 'ไม่ทราบพันธุ์';
            String dogImage = dogData['photoUrl'] ?? 'https://via.placeholder.com/150';
            
            String ownerName = trackingInfo['contactName'] ?? 'ไม่ระบุ';
            String ownerPhone = trackingInfo['phone'] ?? 'ไม่ระบุ';
            String ownerAddress = trackingInfo['address'] ?? 'ไม่ระบุ';
            String note = trackingInfo['note'] ?? '-';
            String status = dogData['currentStatus'] ?? 'ปกติ';

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
                      status == 'หาย' ? 'กำลังตามหาสุนัข' : 'สถานะ: ปกติ',
                      style: GoogleFonts.mitr(
                        color: status == 'หาย' ? Colors.red.shade800 : Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // รูปหมาและชื่อ
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(dogImage),
                    backgroundColor: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 15),
                  Text(dogName, style: GoogleFonts.mitr(fontSize: 26, fontWeight: FontWeight.bold)),
                  Text(breed, style: GoogleFonts.mitr(fontSize: 16, color: Colors.grey.shade600)),
                  
                  const SizedBox(height: 30),

                  // ข้อมูลติดต่อเจ้าของ
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("ข้อมูลติดต่อเจ้าของ", style: GoogleFonts.mitr(fontSize: 18, fontWeight: FontWeight.w500)),
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
                  
                  // ปุ่มโทรออก (กรณีทำต่อยอด สามารถใส่ฟังก์ชัน url_launcher เพื่อโทรได้)
                  if (ownerPhone != 'ไม่ระบุ')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: ใส่ฟังก์ชันโทรออกด้วยแพ็กเกจ url_launcher
                        },
                        icon: const Icon(Icons.phone, color: Colors.black87),
                        label: Text("โทรติดต่อเจ้าของ", style: GoogleFonts.mitr(fontSize: 16, color: Colors.black87)),
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

  // Widget ช่วยสร้างแถวข้อมูล
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          SizedBox(width: 70, child: Text(label, style: GoogleFonts.mitr(color: Colors.grey.shade600))),
          Expanded(child: Text(value, style: GoogleFonts.mitr(fontWeight: FontWeight.w400))),
        ],
      ),
    );
  }
}