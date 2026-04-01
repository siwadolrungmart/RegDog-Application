import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:regdogapp/component/bar.dart'; 
import 'package:regdogapp/service/dogdatabase_service.dart';
import 'package:regdogapp/providers/current_dog_provider.dart';

class QrCodePage extends StatefulWidget {
  const QrCodePage({super.key});

  @override
  State<QrCodePage> createState() => _QrCodePageState();
}

class _QrCodePageState extends State<QrCodePage> {
  final DatabaseService _dbService = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  
  int _currentIndex = 0;
  
  bool _hasData = false; 
  bool _isLoading = false;

  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String _dogStatus = 'ไม่ระบุ';

  String _qrDataLink = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingData();
    });
  }

  void _loadExistingData() {
    final provider = Provider.of<CurrentDogProvider>(context, listen: false);
    
    // ตรงนี้ยังใช้ Provider โหลดข้อมูลแบบฟอร์มค้างไว้ได้ (ถ้ามี)
    if (provider.qrTrackingData != null && provider.qrTrackingData!.isNotEmpty) {
      setState(() {
        _ownerNameController.text = provider.ownerContactName;
        _phoneController.text = provider.ownerPhone;
        _addressController.text = provider.ownerAddress;
        _noteController.text = provider.ownerNote;
        
        String status = provider.currentStatus;
        if (!['ไม่ระบุ', 'ปกติ', 'หาย'].contains(status)) status = 'ไม่ระบุ';
        _dogStatus = status;
        
        _qrDataLink = _dbService.generateQrWebLink(provider.currentDogId ?? '');
        _hasData = true; 
      });
    }
  }

  @override
  void dispose() {
    _ownerNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

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
    if (months < 0) {
      years--;
      months += 12;
    }

    List<String> ageParts = [];
    if (years > 0) ageParts.add('$years ปี');
    if (months > 0) ageParts.add('$months เดือน');
    if (days > 0) ageParts.add('$days วัน');

    return ageParts.isEmpty ? 'เกิดวันนี้' : ageParts.join(' ');
  }

  Future<void> _generateQrCode() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<CurrentDogProvider>(context, listen: false);
    final String dogId = provider.currentDogId ?? '';

    if (dogId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่พบข้อมูลสุนัข'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    String link = _dbService.generateQrWebLink(dogId);
    String? uploadedQrUrl;

    try {
      final validationResult = QrValidator.validate(data: link, version: QrVersions.auto, errorCorrectionLevel: QrErrorCorrectLevel.H);
      if (validationResult.status == QrValidationStatus.valid) {
        final painter = QrPainter.withQr(qr: validationResult.qrCode!, color: const Color(0xFF000000), emptyColor: const Color(0xFFFFFFFF), gapless: true);
        final picData = await painter.toImageData(1024, format: ui.ImageByteFormat.png);
        
        if (picData != null) {
          final Uint8List bytes = picData.buffer.asUint8List();
          final ref = FirebaseStorage.instance.ref().child('qr_codes/dog_$dogId.png');
          await ref.putData(bytes, SettableMetadata(contentType: 'image/png'));
          uploadedQrUrl = await ref.getDownloadURL();
        }
      }
    } catch (e) {
      debugPrint("❌ Error uploading QR Image: $e");
    }

    bool success = await _dbService.saveQrTrackingInfo(
      dogId: dogId,
      ownerContactName: _ownerNameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      note: _noteController.text.trim(),
      dogStatus: _dogStatus,
    );

    if (uploadedQrUrl != null) {
      await FirebaseFirestore.instance.collection('dogs').doc(dogId).set({
        'qrImageUrl': uploadedQrUrl,
      }, SetOptions(merge: true));
    }

    // สั่ง Provider โหลดข้อมูลใหม่หลังจากเราสร้าง QR ไปแล้ว
    await provider.selectDogById(dogId);

    setState(() {
      _isLoading = false;
      if (success) {
        _qrDataLink = link;
        _hasData = true; 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('บันทึกและสร้างคิวอาร์โค้ดสำเร็จ!'), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เกิดข้อผิดพลาด'), backgroundColor: Colors.red));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🟢 ดึง dogId มาจาก Provider ก่อน เพื่อเอาไปค้นหาใน Database
    final provider = Provider.of<CurrentDogProvider>(context);
    final currentDogId = provider.currentDogId;

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading || currentDogId == null
                ? const Center(child: CircularProgressIndicator())
                // 🟢 ใช้ FutureBuilder เพื่อดึงข้อมูลสดๆ จาก Firebase โดยตรงด้วย dogId
                : FutureBuilder<DocumentSnapshot>(
                    future: _dbService.getDogById(currentDogId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: Text("กำลังโหลดข้อมูลจากฐานข้อมูล...", style: GoogleFonts.inter()));
                      }
                      
                      if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                        return Center(child: Text("ไม่พบข้อมูลสุนัข", style: GoogleFonts.inter()));
                      }

                      // 🟢 แปลงข้อมูลที่ได้จาก Firebase มาเป็น Map
                      Map<String, dynamic> rawData = snapshot.data!.data() as Map<String, dynamic>;

                      DateTime? birthDate;
                      if (rawData['birthDate'] is Timestamp) {
                        birthDate = (rawData['birthDate'] as Timestamp).toDate();
                      }
                      
                      final String? qrImageUrl = rawData['qrImageUrl'];
                      
                      String weightText = 'ไม่ระบุ';
                      if (rawData['weight'] != null) {
                         weightText = '${rawData['weight']} กก.';
                      }

                      // 🟢 จัดเตรียมข้อมูลสำหรับส่งเข้าหน้า UI
                      final Map<String, String> dogData = {
                        'name': rawData['name'] ?? 'ไม่ระบุ',
                        'gender': rawData['gender'] ?? 'ไม่ระบุ',
                        'breed': rawData['breed'] ?? 'ไม่ระบุ',
                        'dob': birthDate != null ? DateFormat('d MMMM yyyy', 'th').format(birthDate) : 'ไม่ระบุ',
                        'age': _calculateAge(birthDate),
                        'weight': weightText,
                        'microchip': (rawData['microchip'] != null && rawData['microchip'].toString().isNotEmpty) ? rawData['microchip'] : 'ไม่มี',
                        'disease': (rawData['diseases'] != null && rawData['diseases'].toString().isNotEmpty) ? rawData['diseases'] : 'ไม่มี',
                        'imageUrl': (rawData['photoUrl'] != null && rawData['photoUrl'].toString().isNotEmpty) ? rawData['photoUrl'] : 'https://via.placeholder.com/150',
                      };

                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: _hasData 
                            ? QrDisplayState(
                                qrLink: _qrDataLink,
                                qrImageUrl: qrImageUrl,
                                onEdit: () => setState(() => _hasData = false), 
                              )
                            : _buildFormState(dogData),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _currentIndex,
        onItemTapped: (index) => setState(() => _currentIndex = index),
      ),
    );
  }

  // ==========================================
  // ส่วน UI: ฟอร์มกรอกข้อมูล 
  // ==========================================
  Widget _buildFormState(Map<String, String> dogData) {
    const Color primaryBlue = Color(0xFFCBE4F0);

    return Form(
      key: _formKey,
      child: Column(
        children: [
          DogProfileHeader(imageUrl: dogData['imageUrl']!, dogName: dogData['name']!),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(15),
              border: Border.all(color: primaryBlue, width: 1.5),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DogInfoSection(dogData: dogData),
                const SizedBox(height: 20),
                OwnerInfoSection(
                  ownerNameController: _ownerNameController, phoneController: _phoneController,
                  addressController: _addressController, noteController: _noteController,
                  currentStatus: _dogStatus,
                  onStatusChanged: (val) { if (val != null) setState(() => _dogStatus = val); },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _generateQrCode,
              icon: const Icon(Icons.check, color: Colors.black87, size: 18),
              label: Text("สร้างคิวอาร์โค้ด", style: GoogleFonts.mitr(color: Colors.black87, fontWeight: FontWeight.w500)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFECA5),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// ==========================================
// ส่วน UI: หน้าแสดง QR Code 
// ==========================================
class QrDisplayState extends StatelessWidget {
  final String qrLink;
  final String? qrImageUrl; 
  final VoidCallback onEdit;

  const QrDisplayState({super.key, required this.qrLink, this.qrImageUrl, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Text("คิวอาร์โค้ดติดตามสุนัข", style: GoogleFonts.mitr(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 30),
        
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
            border: Border.all(color: const Color(0xFFCBE4F0), width: 1.5),
          ),
          child: qrImageUrl != null && qrImageUrl!.isNotEmpty
              ? Image.network(
                  qrImageUrl!,
                  width: 220, height: 220, fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(width: 220, height: 220, child: Center(child: CircularProgressIndicator()));
                  },
                  errorBuilder: (context, error, stackTrace) => QrImageView(data: qrLink, size: 220),
                )
              : QrImageView(data: qrLink, version: QrVersions.auto, size: 220.0, backgroundColor: Colors.white),
        ),
        
        const SizedBox(height: 20),
        Text("ใช้คิวอาร์โค้ดหรือลิงก์เพื่อให้\nผู้ใช้สแกนดูข้อมูลสุนัข", textAlign: TextAlign.center, style: GoogleFonts.mitr(color: Colors.grey.shade600, fontSize: 14)),
        const SizedBox(height: 40),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIconAction(Icons.link, "คัดลอกลิงก์", () { /* TODO */ }),
            const SizedBox(width: 40),
            _buildIconAction(Icons.ios_share, "แชร์", () { /* TODO */ }),
            const SizedBox(width: 40),
            _buildIconAction(Icons.download_outlined, "บันทึก", () { /* TODO */ }),
          ],
        ),
        
        const SizedBox(height: 40),
        OutlinedButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit, color: Colors.black87, size: 18),
          label: Text("แก้ไขคิวอาร์โค้ด", style: GoogleFonts.mitr(color: Colors.black87, fontWeight: FontWeight.w500)),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white, side: const BorderSide(color: Color(0xFFFFECA5), width: 2),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
        ),
      ],
    );
  }

  Widget _buildIconAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFCBE4F0).withOpacity(0.5), shape: BoxShape.circle),
            child: Icon(icon, size: 28, color: const Color(0xFF4A7A8C)),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.mitr(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.black87)),
        ],
      ),
    );
  }
}

// ==========================================
// ส่วน UI: Components ย่อย 
// ==========================================
class DogProfileHeader extends StatelessWidget {
  final String imageUrl, dogName;
  const DogProfileHeader({super.key, required this.imageUrl, required this.dogName});
  @override
  Widget build(BuildContext context) => Column(children: [
    CircleAvatar(radius: 50, backgroundImage: NetworkImage(imageUrl), backgroundColor: Colors.grey.shade200), 
    const SizedBox(height: 12), Text(dogName, style: GoogleFonts.mitr(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87))
  ]);
}

class DogInfoSection extends StatelessWidget {
  final Map<String, String> dogData;
  const DogInfoSection({super.key, required this.dogData});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
    Text("ข้อมูลส่วนตัวสุนัข", style: GoogleFonts.mitr(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87)), 
    const SizedBox(height: 16), 
    _row("ชื่อ:", dogData['name']!), 
    _row("เพศ:", dogData['gender']!), 
    _row("สายพันธุ์:", dogData['breed']!), 
    _row("วันเกิด:", dogData['dob']!), 
    _row("อายุ:", dogData['age']!), 
    _row("น้ำหนัก:", dogData['weight']!),
    _row("ไมโครชิพ:", dogData['microchip']!), 
    _row("โรคประจำตัว:", dogData['disease']!, isLast: true)
  ]);
  
  Widget _row(String label, String val, {bool isLast=false}) => Column(children: [
    Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 100, child: Text(label, style: GoogleFonts.mitr(color: Colors.black54, fontWeight: FontWeight.w400))), 
      Expanded(child: Text(val, style: GoogleFonts.mitr(color: Colors.black87, fontWeight: FontWeight.w400)))
    ])), 
    if (!isLast) const Divider(color: Color(0xFFEEEEEE), height: 1)
  ]);
}

class OwnerInfoSection extends StatelessWidget {
  final TextEditingController ownerNameController, phoneController, addressController, noteController;
  final String currentStatus;
  final ValueChanged<String?> onStatusChanged;
  const OwnerInfoSection({super.key, required this.ownerNameController, required this.phoneController, required this.addressController, required this.noteController, required this.currentStatus, required this.onStatusChanged});
  
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
    Text("ข้อมูลติดต่อเจ้าของ", style: GoogleFonts.mitr(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87)), 
    const SizedBox(height: 16),
    _inputRow("ชื่อ:", ownerNameController, "ระบุชื่อเจ้าของ"), 
    _inputRow("เบอร์โทร:", phoneController, "ระบุเบอร์โทรศัพท์", isPhone: true), 
    _inputRow("ที่อยู่:", addressController, "ระบุที่อยู่ปัจจุบัน"),
    const SizedBox(height: 10), Align(alignment: Alignment.centerLeft, child: Text("คำอธิบายเพิ่มเติม:", style: GoogleFonts.mitr(color: Colors.black54, fontWeight: FontWeight.w400))), 
    const SizedBox(height: 8),
    TextFormField(
      controller: noteController, maxLines: 3, 
      decoration: InputDecoration(hintText: "เช่น ลักษณะเด่น ปลอกคอ", hintStyle: GoogleFonts.mitr(color: Colors.grey.shade400, fontSize: 14), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFEEEEEE))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBE4F0))), contentPadding: const EdgeInsets.all(12)), 
      style: GoogleFonts.mitr(color: Colors.black87),
    ),
    const SizedBox(height: 16),
    Row(children: [
      Text("สถานะสุนัข:", style: GoogleFonts.mitr(color: Colors.black54, fontWeight: FontWeight.w400)), const SizedBox(width: 16), 
      Container(height: 40, padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFCBE4F0)), borderRadius: BorderRadius.circular(20)), 
        child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: currentStatus, icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54), items: ['ไม่ระบุ', 'ปกติ', 'หาย'].map((v) => DropdownMenuItem(value: v, child: Text(v, style: GoogleFonts.mitr()))).toList(), onChanged: onStatusChanged))
      )
    ])
  ]);

  Widget _inputRow(String label, TextEditingController controller, String hint, {bool isPhone=false}) => Column(children: [
    Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      SizedBox(width: 100, child: Text(label, style: GoogleFonts.mitr(color: Colors.black54, fontWeight: FontWeight.w400))), 
      Expanded(
        child: TextFormField(
          controller: controller, 
          keyboardType: isPhone ? TextInputType.phone : TextInputType.text, 
          inputFormatters: isPhone ? [FilteringTextInputFormatter.digitsOnly] : [],
          decoration: InputDecoration(hintText: hint, hintStyle: GoogleFonts.mitr(color: Colors.grey.shade400, fontSize: 14), border: InputBorder.none, isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 10)), 
          style: GoogleFonts.mitr(color: Colors.black87), 
          validator: (val) => val!.isEmpty ? 'กรุณากรอกข้อมูล' : null
        )
      )
    ]), const Divider(color: Color(0xFFEEEEEE), height: 1), const SizedBox(height: 8)
  ]);
}