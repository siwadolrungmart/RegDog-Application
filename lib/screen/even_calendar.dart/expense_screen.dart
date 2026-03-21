// ชื่อไฟล์: expense_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import 'package:regdogapp/component/upperbar.dart';
import 'package:regdogapp/screen/dog_list.dart';
import 'package:regdogapp/service/notification_service.dart'; // อาจจะเก็บไว้ใช้ตอนลบ event
import 'package:regdogapp/providers/current_dog_provider.dart';

class AddExpenseEventPage extends StatefulWidget {
  final DateTime selectedDateFromCalendar;
  final String? eventId;
  final Map<String, dynamic>? eventData;

  const AddExpenseEventPage({
    super.key,
    required this.selectedDateFromCalendar,
    this.eventId,
    this.eventData,
  });

  @override
  State<AddExpenseEventPage> createState() => _AddExpenseEventPageState();
}

class _AddExpenseEventPageState extends State<AddExpenseEventPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController(text: "ค่าใช้จ่าย");
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  TimeOfDay _selectedTime = TimeOfDay.now();

  final List<File> _selectedLocalImages = [];
  List<String> _existingImageUrls = [];
  final List<String> _deletedImageUrls = [];

  final ImagePicker _picker = ImagePicker();

  String _getThaiDate(DateTime date) {
    const List<String> thaiMonths = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม',
    ];
    return "${date.day} ${thaiMonths[date.month - 1]} ${date.year}";
  }

  @override
  void initState() {
    super.initState();
    if (widget.eventData != null) {
      final data = widget.eventData!;

      _nameController.text = data['name'] ?? "ค่าใช้จ่าย";
      _noteController.text = data['note'] ?? "";
      
      if (data['cost'] != null) {
        _costController.text = data['cost'].toString();
      }

      if (data['images'] != null) {
        _existingImageUrls = List<String>.from(data['images']);
      }

      if (data['start_time'] != null) {
        DateTime? start;
        if (data['start_time'] is Timestamp) {
          start = (data['start_time'] as Timestamp).toDate();
        } else if (data['start_time'] is String) {
          start = DateTime.tryParse(data['start_time']);
        }
        if (start != null) {
          _selectedTime = TimeOfDay(hour: start.hour, minute: start.minute);
        }
      }
    }
  }

  int get _totalImageCount => _existingImageUrls.length + _selectedLocalImages.length;

  Future<void> _pickImage() async {
    if (_totalImageCount >= 4) {
      _showErrorSnackBar("เพิ่มรูปภาพได้สูงสุด 4 รูปเท่านั้น (เช่น ใบเสร็จ)");
      return;
    }

    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File file = File(pickedFile.path);
      double fileSizeInMB = file.lengthSync() / (1024 * 1024);

      if (fileSizeInMB > 5.0) {
        _showErrorSnackBar("ขนาดรูปภาพเกิน 5 MB (ไฟล์นี้ขนาด ${fileSizeInMB.toStringAsFixed(2)} MB)");
        return;
      }
      setState(() => _selectedLocalImages.add(file));
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      _deletedImageUrls.add(_existingImageUrls[index]);
      _existingImageUrls.removeAt(index);
    });
  }

  void _removeLocalImage(int index) {
    setState(() => _selectedLocalImages.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF90C2D8);
    const Color bgBlue = Color(0xFFE6F3FB);
    const Color textLabelBlue = Color(0xFF6A97A8);
    const Color yellowBtn = Color(0xFFFFEFA6);

    return Scaffold(
      bottomNavigationBar: _buildStickyBottomBar(yellowBtn),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HomeTopBar(
                showProfile: true,
                onMenuTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DogListPage()),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 15),
                    _buildActivityImages(bgBlue, primaryBlue),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primaryBlue.withOpacity(0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFormRow(
                            "ชื่อ:",
                            _buildInputBox(_nameController, "ชื่อค่าใช้จ่าย", TextInputType.text),
                            textLabelBlue,
                          ),
                          _buildDivider(),
                          _buildFormRow(
                            "วัน:",
                            _buildPlainText(_getThaiDate(widget.selectedDateFromCalendar)),
                            textLabelBlue,
                          ),
                          _buildDivider(),
                          _buildFormRow(
                            "เวลา:",
                            _buildTimePicker(context),
                            textLabelBlue,
                          ),
                          _buildDivider(),
                          _buildFormRow(
                            "จำนวนเงิน:",
                            _buildNumberInputBox(_costController, "0.00"), 
                            textLabelBlue,
                          ),
                          _buildDivider(),
                          _buildFormRow(
                            "โน้ต:",
                            _buildInputBox(_noteController, "โน๊ตเพิ่มเติม...", TextInputType.multiline),
                            textLabelBlue,
                          ),
                          // 🟢 นำส่วนแจ้งเตือนและการทำซ้ำออกไปแล้ว
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteEvent() async {
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("ลบค่าใช้จ่าย", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            content: Text("คุณแน่ใจหรือไม่ว่าต้องการลบรายการค่าใช้จ่ายนี้?", style: GoogleFonts.inter()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("ยกเลิก", style: GoogleFonts.inter(color: Colors.grey[700])),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("ลบข้อมูล", style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ) ?? false;

    if (confirm && widget.eventId != null) {
      try {
        for (String url in _existingImageUrls) {
          try {
            await FirebaseStorage.instance.refFromURL(url).delete();
          } catch (e) {
            debugPrint("Storage delete error: $e");
          }
        }

        await _firestore.collection('dog_activities').doc(widget.eventId).delete();
        await NotificationService.cancelEventNotifications(widget.eventId!);

        if (mounted) {
          final messenger = ScaffoldMessenger.of(context);
          Navigator.pop(context);
          messenger.showSnackBar(
            const SnackBar(content: Text("ลบรายการเรียบร้อยแล้ว"), backgroundColor: Colors.redAccent),
          );
        }
      } catch (e) {
        _showErrorSnackBar("เกิดข้อผิดพลาดในการลบ: $e");
      }
    }
  }

  Future<void> _saveToFirebase() async {
    final DateTime startDateTime = DateTime(
      widget.selectedDateFromCalendar.year,
      widget.selectedDateFromCalendar.month,
      widget.selectedDateFromCalendar.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    double parsedCost = double.tryParse(_costController.text.replaceAll(',', '')) ?? 0.0;
    if (_costController.text.trim().isEmpty) {
      _showErrorSnackBar("กรุณากรอกจำนวนเงิน");
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final currentDogId = Provider.of<CurrentDogProvider>(context, listen: false).currentDogId;
      if (currentDogId == null) {
        Navigator.pop(context); 
        _showErrorSnackBar("กรุณาเลือกน้องหมาก่อนบันทึก");
        return;
      }

      for (String url in _deletedImageUrls) {
        try {
          await FirebaseStorage.instance.refFromURL(url).delete();
        } catch (e) {
          debugPrint("Storage delete orphaned image error: $e");
        }
      }

      List<String> uploadedImageUrls = [];
      for (File imageFile in _selectedLocalImages) {
        String fileName = 'activities/${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
        Reference ref = FirebaseStorage.instance.ref().child(fileName);
        await ref.putFile(imageFile);
        String downloadUrl = await ref.getDownloadURL();
        uploadedImageUrls.add(downloadUrl);
      }

      List<String> finalImagesToSave = [..._existingImageUrls, ...uploadedImageUrls];

      Map<String, dynamic> payload = {
        'type': 'expense', 
        'dog_id': currentDogId,
        'name': _nameController.text,
        'start_time': Timestamp.fromDate(startDateTime),
        'cost': parsedCost,
        'note': _noteController.text,
        'images': finalImagesToSave,
        'updated_at': FieldValue.serverTimestamp(),
        // 🟢 ไม่ส่งค่าการแจ้งเตือนและการทำซ้ำขึ้น Database อีกต่อไป
      };

      if (widget.eventId == null) {
        payload['created_at'] = FieldValue.serverTimestamp();
        await _firestore.collection('dog_activities').add(payload);
      } else {
        await _firestore.collection('dog_activities').doc(widget.eventId).update(payload);
      }

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context); // ปิด Loading
        Navigator.pop(context); // กลับหน้าก่อนหน้า
        messenger.showSnackBar(
          const SnackBar(content: Text("บันทึกค่าใช้จ่ายเรียบร้อยแล้ว"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showErrorSnackBar("เกิดข้อผิดพลาดในการบันทึกข้อมูล: $e");
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent, duration: const Duration(seconds: 3)),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        Expanded(
          child: Center(
            child: Text(
              widget.eventId == null ? "เพิ่มรายการค่าใช้จ่าย" : "รายละเอียดค่าใช้จ่าย",
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        if (widget.eventId != null)
          IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: _deleteEvent)
        else
          const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildActivityImages(Color bg, Color iconCol) {
    List<Widget> imageWidgets = [];
    for (int i = 0; i < _existingImageUrls.length; i++) {
      imageWidgets.add(_buildImageThumbnail(
        imageProvider: NetworkImage(_existingImageUrls[i]), iconCol: iconCol, onRemove: () => _removeExistingImage(i),
      ));
    }
    for (int i = 0; i < _selectedLocalImages.length; i++) {
      imageWidgets.add(_buildImageThumbnail(
        imageProvider: FileImage(_selectedLocalImages[i]), iconCol: iconCol, onRemove: () => _removeLocalImage(i),
      ));
    }
    if (_totalImageCount < 4) {
      imageWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: GestureDetector(
            onTap: _pickImage,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 75, height: 75,
                  decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                  child: Icon(Icons.payments, color: iconCol, size: 40), 
                ),
                Container(
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: iconCol, width: 1.5)),
                  child: Icon(Icons.add, color: iconCol, size: 20),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Column(
      children: [
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: imageWidgets)),
        const SizedBox(height: 10),
        Text("ค่าใช้จ่าย", style: GoogleFonts.inter(color: iconCol, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildImageThumbnail({required ImageProvider imageProvider, required Color iconCol, required VoidCallback onRemove}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Container(
            width: 75, height: 75,
            decoration: BoxDecoration(
              shape: BoxShape.circle, border: Border.all(color: iconCol, width: 2),
              image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.cancel, color: Colors.redAccent, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormRow(String label, Widget child, Color labelColor) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: 95, child: Text(label, style: GoogleFonts.inter(color: labelColor, fontSize: 14))),
            Expanded(child: child),
          ],
        ),
      );

  Widget _buildInputBox(TextEditingController controller, String hint, TextInputType kType) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
        child: TextField(
          controller: controller,
          maxLines: kType == TextInputType.multiline ? null : 1,
          keyboardType: kType,
          decoration: InputDecoration(hintText: hint, border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
          style: const TextStyle(fontSize: 14),
        ),
      );

  Widget _buildNumberInputBox(TextEditingController controller, String hint) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: InputDecoration(hintText: hint, border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                style: const TextStyle(fontSize: 14, color: Colors.blue, fontWeight: FontWeight.bold),
              ),
            ),
            Text("บาท", style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700])),
          ],
        ),
      );

  Widget _buildDivider() => const Divider(height: 20, thickness: 1, color: Color(0xFFF0F0F0));

  Widget _buildPlainText(String t) => Text(t, style: const TextStyle(fontSize: 14));

  Widget _buildTimePicker(BuildContext context) => InkWell(
        onTap: () async {
          final time = await showTimePicker(context: context, initialTime: _selectedTime);
          if (time != null) setState(() => _selectedTime = time);
        },
        child: Text("${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')} น.", style: const TextStyle(color: Colors.blue)),
      );

  Widget _buildStickyBottomBar(Color col) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))]),
        child: SizedBox(
          height: 55,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: col, foregroundColor: Colors.black87, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: _saveToFirebase,
            icon: const Icon(Icons.check, size: 24),
            label: Text(widget.eventId == null ? "บันทึกค่าใช้จ่าย" : "อัปเดต", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}