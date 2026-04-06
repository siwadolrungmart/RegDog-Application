import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart'; 

class QrScanResultPage extends StatefulWidget {
  final String dogId; 

  const QrScanResultPage({super.key, required this.dogId});

  @override
  State<QrScanResultPage> createState() => _QrScanResultPageState();
}

class _QrScanResultPageState extends State<QrScanResultPage> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _dogData;
  bool _hasNotified = false; // ตัวล็อกไม่ให้ส่งแจ้งเตือนซ้ำ

  @override
  void initState() {
    super.initState();
    _fetchDataAndNotify();
  }

  // 🟢 ฟังก์ชันดึงข้อมูล และ ส่งแจ้งเตือน (ทำครั้งเดียวตอนเปิดหน้า)
  Future<void> _fetchDataAndNotify() async {
    final params = Uri.base.queryParameters;
    final String resolvedDogId = params['dogId'] ?? widget.dogId; 
    final String scannedToken = params['token'] ?? '';

    if (resolvedDogId.isEmpty || resolvedDogId == "null") {
      setState(() { _errorMessage = '❌ ลิงก์ไม่ถูกต้อง\nไม่พบรหัสสุนัข'; _isLoading = false; });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('dogs').doc(resolvedDogId).get();
      
      if (!doc.exists) {
        setState(() { _errorMessage = 'ไม่พบข้อมูลสุนัขในระบบ\nอาจถูกลบหรือรหัสไม่ถูกต้อง'; _isLoading = false; });
        return;
      }

      var dogData = doc.data() as Map<String, dynamic>;
      String dbToken = dogData['activeQrToken'] ?? ''; 
      bool isQrActive = dogData['isQrActive'] ?? false;
      
      if (!isQrActive) {
        setState(() { _errorMessage = 'สุนัขตัวนี้ยังไม่ได้เปิดใช้งาน\nระบบคิวอาร์โค้ด'; _isLoading = false; });
        return;
      }

      if (dbToken.isNotEmpty && scannedToken != dbToken) {
        setState(() { _errorMessage = '❌ คิวอาร์โค้ดนี้หมดอายุแล้ว\nกรุณาสแกนคิวอาร์โค้ดล่าสุด'; _isLoading = false; });
        return;
      }

      // 🚀 ยืนยันข้อมูลสำเร็จ -> ส่งการแจ้งเตือน!
      if (!_hasNotified) {
        await _sendNotification(resolvedDogId, dogData);
        _hasNotified = true;
      }

      setState(() {
        _dogData = dogData;
        _isLoading = false;
      });

    } catch (e) {
      setState(() { _errorMessage = 'เกิดข้อผิดพลาดในการโหลดข้อมูล'; _isLoading = false; });
    }
  }

  // 📧 ฟังก์ชันส่งการแจ้งเตือน (ดึง Email จาก users)
  Future<void> _sendNotification(String dogId, Map<String, dynamic> dogData) async {
    try {
      String dogName = dogData['name'] ?? 'น้องหมาของคุณ';
      String ownerId = dogData['ownerId'] ?? '';
      String ownerEmail = '';

      // 1. บันทึกประวัติการสแกนลง Firestore
      await FirebaseFirestore.instance.collection('dogs').doc(dogId).collection('scan_history').add({
        'scannedAt': FieldValue.serverTimestamp(),
        'message': 'มีคนสแกนคิวอาร์โค้ดของ $dogName',
      });

      // 2. ดึงข้อมูลอีเมลของเจ้าของจาก Collection 'users'
      if (ownerId.isNotEmpty) {
        try {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(ownerId).get();
          if (userDoc.exists) {
            var userData = userDoc.data() as Map<String, dynamic>;
            ownerEmail = userData['email'] ?? '';
          }
        } catch (e) {
          debugPrint("ไม่สามารถดึงข้อมูล User ได้: $e");
        }
      }

      // 3. ส่งอีเมลผ่าน Firebase Trigger Email
      if (ownerEmail.isNotEmpty) {
        await FirebaseFirestore.instance.collection('mail').add({
          'to': ownerEmail,
          'message': {
            'subject': '🚨 แจ้งเตือน! มีผู้สแกนคิวอาร์โค้ดของ $dogName',
            'html': '''
              <div style="font-family: sans-serif; padding: 20px; color: #333; max-width: 600px; margin: 0 auto; border: 1px solid #eee; border-radius: 10px;">
                <h2 style="color: #4A7A8C; text-align: center;">มีคนพบเห็น $dogName แล้ว!</h2>
                <div style="text-align: center; margin: 20px 0;">
                  <img src="https://cdn-icons-png.flaticon.com/512/2911/2911738.png" width="80" alt="Dog Alert">
                </div>
                <p>สวัสดีครับ,</p>
                <p>ระบบ RegDog ได้รับแจ้งว่า <b>เพิ่งมีการสแกนป้ายประจำตัวของ $dogName</b> เมื่อสักครู่นี้</p>
                <p>โปรดเตรียมรับสายโทรศัพท์ตามเบอร์ <b>${dogData['qrTrackingData']?['phone'] ?? 'ที่คุณระบุไว้'}</b> เผื่อมีพลเมืองดีติดต่อกลับไปนะครับ ขอให้น้องหมาปลอดภัยครับ!</p>
                <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
                <p style="font-size: 12px; color: #999; text-align: center;">นี่คืออีเมลอัตโนมัติจากระบบ RegDog App กรุณาอย่าตอบกลับ</p>
              </div>
            ''',
          }
        });
        debugPrint('ส่งคำสั่งอีเมลแจ้งเตือนสำเร็จ!');
      } else {
        debugPrint('ไม่พบอีเมลของเจ้าของ');
      }
    } catch (e) {
      debugPrint("Send notification error: $e");
    }
  }

  // --- ฟังก์ชันช่วยเหลือ ---
  String _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int years = now.year - birthDate.year;
    int months = now.month - birthDate.month;
    int days = now.day - birthDate.day;

    if (days < 0) { months--; days += DateTime(now.year, now.month, 0).day; }
    if (months < 0) { years--; months += 12; }

    if (years > 0) return '$years ปี $months เดือน';
    if (months > 0) return '$months เดือน $days วัน';
    return '$days วัน';
  }

  String _formatThaiDate(DateTime date) {
    const thaiMonths = ['มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน', 'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'];
    return '${date.day} ${thaiMonths[date.month - 1]} ${date.year + 543}';
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg_watercolor.png'), 
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF4A7A8C)));
    }

    if (_errorMessage != null) {
      return _buildErrorState(_errorMessage!);
    }

    if (_dogData == null) {
      return _buildErrorState('ไม่พบข้อมูล');
    }

    // 🐶 ดึงข้อมูลมาแสดงผล
    String dogName = _dogData!['name'] ?? 'ไม่ระบุ';
    String breed = _dogData!['breed'] ?? 'ไม่ระบุ';
    String gender = _dogData!['gender'] ?? 'ไม่ระบุ';
    String dogImage = (_dogData!['photoUrl'] != null && _dogData!['photoUrl'].toString().isNotEmpty) 
        ? _dogData!['photoUrl'] 
        : 'https://via.placeholder.com/150';
    String status = _dogData!['currentStatus'] ?? 'ปกติ';

    String dobStr = 'ไม่ระบุ';
    String ageStr = 'ไม่ทราบอายุ';
    if (_dogData!['birthDate'] is Timestamp) {
      DateTime dob = (_dogData!['birthDate'] as Timestamp).toDate();
      dobStr = _formatThaiDate(dob); 
      ageStr = _calculateAge(dob);
    }

    var tracking = _dogData!['qrTrackingData'] as Map<String, dynamic>? ?? {};
    String ownerName = tracking['contactName'] ?? 'ไม่ระบุ';
    String ownerPhone = tracking['phone'] ?? 'ไม่ระบุ';
    String ownerAddress = tracking['address'] ?? 'ไม่ระบุ';
    String note = tracking['note'] ?? '-';
    String weightText = _dogData!['weight']?.toString() ?? tracking['weight']?.toString() ?? '0';
    String weight = (weightText != '0' && weightText.isNotEmpty) ? "$weightText กก." : "ไม่ระบุ";
    
    // ป้องกัน Error หากไมโครชิพและโรคไม่มีในบางข้อมูล
    String microchip = (_dogData!['microchip']?.toString().isNotEmpty ?? false) ? _dogData!['microchip'] : 'ไม่มี';
    String diseases = (_dogData!['diseases']?.toString().isNotEmpty ?? false) ? _dogData!['diseases'] : 'ไม่มี';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildStatusBadge(status),
          const SizedBox(height: 25),
          _buildProfileImage(dogImage),
          const SizedBox(height: 15),
          Text(dogName, style: GoogleFonts.mitr(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
          Text(breed, style: GoogleFonts.mitr(fontSize: 18, color: Colors.black54)),
          const SizedBox(height: 30),

          _buildDataCard("ข้อมูลส่วนตัวสุนัข", [
            _infoRow(Icons.pets, "เพศ:", gender),
            _infoRow(Icons.cake, "วันเกิด:", dobStr),
            _infoRow(Icons.calendar_month, "อายุ:", ageStr),
            _infoRow(Icons.scale, "น้ำหนัก:", weight),
            _infoRow(Icons.memory, "ไมโครชิพ:", microchip),
            _infoRow(Icons.medical_services_outlined, "โรคประจำตัว:", diseases),
          ]),
          const SizedBox(height: 20),

          _buildDataCard("ข้อมูลติดต่อเจ้าของ", [
            _infoRow(Icons.person, "ชื่อ:", ownerName),
            _infoRow(Icons.phone, "เบอร์โทร:", ownerPhone),
            _infoRow(Icons.location_on, "ที่อยู่:", ownerAddress),
            _infoRow(Icons.info_outline, "หมายเหตุ:", note),
          ]),
          const SizedBox(height: 30),
          
          if (ownerPhone != 'ไม่ระบุ' && ownerPhone.isNotEmpty)
            _buildCallButton(ownerPhone),
          
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  // --- UI Components ---
  Widget _buildStatusBadge(String status) {
    bool isLost = status == 'หาย';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(color: isLost ? Colors.red.shade50 : Colors.green.shade50, borderRadius: BorderRadius.circular(30), border: Border.all(color: isLost ? Colors.red.shade200 : Colors.green.shade200)),
      child: Text(isLost ? '📢 กำลังตามหาสุนัข' : '✅ สถานะ: ปกติ', style: GoogleFonts.mitr(color: isLost ? Colors.red.shade700 : Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildProfileImage(String url) {
    return Container(
      width: 140, height: 140,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 5), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]),
      child: ClipOval(child: Image.network(url, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.pets, size: 80, color: Colors.grey))),
    );
  }

  Widget _buildDataCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.mitr(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF4A7A8C))),
        const Divider(height: 30, thickness: 1),
        ...children
      ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: const Color(0xFFCBE4F0)), const SizedBox(width: 12),
        SizedBox(width: 90, child: Text(label, style: GoogleFonts.mitr(color: Colors.black54, fontSize: 14))),
        Expanded(child: Text(value, style: GoogleFonts.mitr(color: Colors.black87, fontSize: 15, fontWeight: FontWeight.w400))),
      ]),
    );
  }

  Widget _buildCallButton(String phone) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _makePhoneCall(phone),
        icon: const Icon(Icons.phone_in_talk, color: Colors.black87),
        label: Text("โทรติดต่อเจ้าของ", style: GoogleFonts.mitr(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.w500)),
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFECA5), padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)), elevation: 3),
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
            const Icon(Icons.info_outline, size: 70, color: Colors.grey), const SizedBox(height: 20),
            Text(message, textAlign: TextAlign.center, style: GoogleFonts.mitr(fontSize: 18, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}