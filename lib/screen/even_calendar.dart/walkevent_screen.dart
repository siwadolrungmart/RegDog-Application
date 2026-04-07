import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart'; // 🟢 1. Import Provider

import 'package:regdogapp/component/upperbar.dart';
import 'package:regdogapp/screen/dog_list.dart';
import 'package:regdogapp/component/duration_picker.dart';
import 'package:regdogapp/component/distance_picker.dart';
import 'package:regdogapp/component/event_settings.dart';
import 'package:regdogapp/screen/navbar_screen/calendar_screen.dart';
import 'package:regdogapp/service/notification_service.dart';
import 'package:regdogapp/providers/current_dog_provider.dart'; // 🟢 2. Import CurrentDogProvider

class AddWalkEventPage extends StatefulWidget {
  final DateTime selectedDateFromCalendar;
  final String? eventId;
  final Map<String, dynamic>? eventData;

  const AddWalkEventPage({
    super.key,
    required this.selectedDateFromCalendar,
    this.eventId,
    this.eventData,
  });

  @override
  State<AddWalkEventPage> createState() => _AddWalkEventPageState();
}

class _AddWalkEventPageState extends State<AddWalkEventPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController(
    text: "เดินเล่น",
  );
  final TextEditingController _noteController = TextEditingController();

  TimeOfDay _selectedTime = TimeOfDay.now();
  Duration? _selectedDuration;
  double? _selectedDistance;

  int? _selectedReminder;
  RecurrenceData _recurrenceData = RecurrenceData(
    repeatType: "none",
    interval: 1,
    weeklyDays: [],
    monthlyMode: 'dayOfMonth',
  );

  final List<File> _selectedLocalImages = [];
  List<String> _existingImageUrls = [];
  final List<String> _deletedImageUrls = [];

  final ImagePicker _picker = ImagePicker();

  String get _formattedDuration => _selectedDuration == null
      ? "เลือกเวลา"
      : "${_selectedDuration!.inHours}:${(_selectedDuration!.inMinutes % 60).toString().padLeft(2, '0')} ชม.";
  String get _formattedDistance {
    if (_selectedDistance == null) return "เลือกระยะทาง";
    String formatted = _selectedDistance!.toStringAsFixed(2);
    if (formatted.endsWith('0'))
      formatted = formatted.substring(0, formatted.length - 1);
    if (formatted.endsWith('.0'))
      formatted = formatted.substring(0, formatted.length - 2);
    return "$formatted กม.";
  }

  String _getThaiDate(DateTime date) {
    const List<String> thaiMonths = [
      'มกราคม',
      'กุมภาพันธ์',
      'มีนาคม',
      'เมษายน',
      'พฤษภาคม',
      'มิถุนายน',
      'กรกฎาคม',
      'สิงหาคม',
      'กันยายน',
      'ตุลาคม',
      'พฤศจิกายน',
      'ธันวาคม',
    ];
    return "${date.day} ${thaiMonths[date.month - 1]} ${date.year}";
  }

  @override
  void initState() {
    super.initState();
    if (widget.eventData != null) {
      final data = widget.eventData!;

      _nameController.text = data['name'] ?? "เดินเล่น";
      _noteController.text = data['note'] ?? "";

      if (data['images'] != null) {
        _existingImageUrls = List<String>.from(data['images']);
      }

      if (data['start_time'] != null) {
        DateTime? start;
        if (data['start_time'] is Timestamp)
          start = (data['start_time'] as Timestamp).toDate();
        else if (data['start_time'] is String)
          start = DateTime.tryParse(data['start_time']);
        if (start != null)
          _selectedTime = TimeOfDay(hour: start.hour, minute: start.minute);
      }

      if (data['duration_minutes'] != null)
        _selectedDuration = Duration(
          minutes: (data['duration_minutes'] as num).toInt(),
        );
      if (data['distance_km'] != null)
        _selectedDistance = (data['distance_km'] as num).toDouble();

      _selectedReminder = data['reminder_offset_minutes'] as int?;

      if (data['recurrence'] != null) {
        var rec = data['recurrence'];
        DateTime? parsedEndDate;
        if (rec['end_date'] != null) {
          if (rec['end_date'] is Timestamp)
            parsedEndDate = (rec['end_date'] as Timestamp).toDate();
          else if (rec['end_date'] is String)
            parsedEndDate = DateTime.tryParse(rec['end_date']);
        }
        _recurrenceData = RecurrenceData(
          repeatType: rec['type'] ?? "none",
          interval: rec['interval'] ?? 1,
          weeklyDays: List<int>.from(rec['days_of_week'] ?? []),
          monthlyMode: rec['monthly_mode'] ?? 'dayOfMonth',
          endDate: parsedEndDate,
          count: rec['count'],
        );
      }
    }
  }

  int get _totalImageCount =>
      _existingImageUrls.length + _selectedLocalImages.length;

  Future<void> _pickImage() async {
    if (_totalImageCount >= 4) {
      _showErrorSnackBar("เพิ่มรูปภาพได้สูงสุด 4 รูปเท่านั้น");
      return;
    }

    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      File file = File(pickedFile.path);
      double fileSizeInMB = file.lengthSync() / (1024 * 1024);

      if (fileSizeInMB > 5.0) {
        _showErrorSnackBar(
          "ขนาดรูปภาพเกิน 5 MB (ไฟล์นี้ขนาด ${fileSizeInMB.toStringAsFixed(2)} MB)",
        );
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
                            _buildInputBox(_nameController, "ชื่อกิจกรรม"),
                            textLabelBlue,
                          ),
                          _buildDivider(),
                          _buildFormRow(
                            "วัน:",
                            _buildPlainText(
                              _getThaiDate(widget.selectedDateFromCalendar),
                            ),
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
                            "ระยะเวลา:",
                            _buildDurationPickerBtn(context),
                            textLabelBlue,
                          ),
                          _buildDivider(),
                          _buildFormRow(
                            "ระยะทาง:",
                            _buildDistancePickerBtn(context),
                            textLabelBlue,
                          ),
                          _buildDivider(),
                          _buildFormRow(
                            "โน้ต:",
                            _buildInputBox(_noteController, "โน้ตเพิ่มเติม..."),
                            textLabelBlue,
                          ),
                          _buildDivider(),
                          _buildFormRow(
                            "แจ้งเตือน:",
                            ReminderPicker(
                              selectedMinutes: _selectedReminder,
                              onChanged: (val) =>
                                  setState(() => _selectedReminder = val),
                            ),
                            textLabelBlue,
                          ),
                          _buildDivider(),
                          RecurrenceSection(
                            labelColor: textLabelBlue,
                            primaryColor: primaryBlue,
                            baseDate: widget.selectedDateFromCalendar,
                            initialData: _recurrenceData,
                            onChanged: (data) => _recurrenceData = data,
                          ),
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
    bool isRecurring = _recurrenceData.repeatType != 'none';
    String dialogContent = isRecurring
        ? "กิจกรรมนี้มีการตั้งค่าทำซ้ำ การลบจะทำให้กิจกรรมที่ทำซ้ำทั้งหมดถูกลบออกจากปฏิทินด้วย\n\nคุณแน่ใจหรือไม่ว่าต้องการลบ?"
        : "คุณแน่ใจหรือไม่ว่าต้องการลบกิจกรรมนี้?";

    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              "ลบกิจกรรม",
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            content: Text(dialogContent, style: GoogleFonts.inter()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  "ยกเลิก",
                  style: GoogleFonts.inter(color: Colors.grey[700]),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  "ลบข้อมูล",
                  style: GoogleFonts.inter(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm && widget.eventId != null) {
      try {
        for (String url in _existingImageUrls) {
          try {
            await FirebaseStorage.instance.refFromURL(url).delete();
          } catch (e) {
            debugPrint("Storage delete error: $e");
          }
        }

        await _firestore
            .collection('dog_activities')
            .doc(widget.eventId)
            .delete();
        await NotificationService.cancelEventNotifications(widget.eventId!);

        if (mounted) {
          final messenger = ScaffoldMessenger.of(context);
          Navigator.pop(context);
          messenger.showSnackBar(
            const SnackBar(
              content: Text("ลบกิจกรรมเรียบร้อยแล้ว"),
              backgroundColor: Colors.redAccent,
            ),
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

    if (_recurrenceData.repeatType == 'weekly' &&
        _recurrenceData.weeklyDays.isEmpty) {
      _showErrorSnackBar("กรุณาเลือกวันในสัปดาห์อย่างน้อย 1 วัน");
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // 🟢 3. เช็คและดึง dog_id ของสุนัขตัวปัจจุบันจาก Provider
      final currentDogId = Provider.of<CurrentDogProvider>(
        context,
        listen: false,
      ).currentDogId;
      if (currentDogId == null) {
        Navigator.pop(context); // ปิด Loading
        _showErrorSnackBar("กรุณาเลือกน้องหมาก่อนบันทึกกิจกรรม");
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
        String fileName =
            'activities/${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
        Reference ref = FirebaseStorage.instance.ref().child(fileName);
        await ref.putFile(imageFile);
        String downloadUrl = await ref.getDownloadURL();
        uploadedImageUrls.add(downloadUrl);
      }

      List<String> finalImagesToSave = [
        ..._existingImageUrls,
        ...uploadedImageUrls,
      ];

      Map<String, dynamic> recurrencePayload = {
        'type': _recurrenceData.repeatType,
        'interval': _recurrenceData.interval,
      };
      if (_recurrenceData.repeatType != 'none') {
        if (_recurrenceData.repeatType == 'weekly')
          recurrencePayload['days_of_week'] = _recurrenceData.weeklyDays;
        if (_recurrenceData.repeatType == 'monthly')
          recurrencePayload['monthly_mode'] = _recurrenceData.monthlyMode;
        if (_recurrenceData.endDate != null)
          recurrencePayload['end_date'] = Timestamp.fromDate(
            _recurrenceData.endDate!,
          );
        else if (_recurrenceData.count != null)
          recurrencePayload['count'] = _recurrenceData.count;
      }

      Map<String, dynamic> payload = {
        'type': 'walk',
        'dog_id': currentDogId, // 🟢 4. เพิ่ม dog_id เข้าไปใน Firestore Payload
        'name': _nameController.text,
        'start_time': Timestamp.fromDate(startDateTime),
        'duration_minutes': _selectedDuration?.inMinutes ?? 0,
        'distance_km': _selectedDistance ?? 0.0,
        'note': _noteController.text,
        'reminder_offset_minutes': _selectedReminder,
        'recurrence': recurrencePayload,
        'images': finalImagesToSave,
        'updated_at': FieldValue.serverTimestamp(),
      };

      String targetEventId = widget.eventId ?? "";

      if (widget.eventId == null) {
        payload['created_at'] = FieldValue.serverTimestamp();
        DocumentReference docRef = await _firestore
            .collection('dog_activities')
            .add(payload);
        targetEventId = docRef.id;
      } else {
        await _firestore
            .collection('dog_activities')
            .doc(widget.eventId)
            .update(payload);
        targetEventId = widget.eventId!;
      }

      String getReminderMessage(int? minutes, String eventName) {
        if (minutes == null) return "";
        if (minutes == 0) return "ถึงเวลากิจกรรม $eventName แล้ว!";
        if (minutes == 60)
          return "เตรียมตัว! กิจกรรม $eventName (1 ชั่วโมง ก่อนหน้า)";
        if (minutes == 1440)
          return "เตรียมตัว! กิจกรรม $eventName (1 วัน ก่อนหน้า)";
        return "เตรียมตัว! กิจกรรม $eventName ($minutes นาที ก่อนหน้า)";
      }

      await NotificationService.scheduleEventNotification(
        eventId: targetEventId,
        title: "แจ้งเตือนกิจกรรม: ${_nameController.text}",
        body: getReminderMessage(_selectedReminder, _nameController.text),
        startDateTime: startDateTime,
        reminderMinutes: _selectedReminder,
        recurrenceData: _recurrenceData,
        payload: targetEventId,
      );

     if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context); // ปิด Loading Dialog

        // 🟢 เปลี่ยนมาใช้คำสั่งนี้ เพื่อเคลียร์หน้าจอและเปิดกลับไปหน้า Calendar พร้อมส่งวันที่ไป
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => CalendarPage(
              selectedDay: widget.selectedDateFromCalendar, // ส่งวันที่กลับไปให้ปฏิทิน
            ),
          ),
          (route) => false,
        );

        messenger.showSnackBar(
          const SnackBar(
            content: Text("บันทึกกิจกรรมเรียบร้อยแล้ว"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint("Error saving to Firebase: $e");
      _showErrorSnackBar("เกิดข้อผิดพลาดในการบันทึกข้อมูล: $e");
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        Expanded(
          child: Center(
            child: Text(
              widget.eventId == null ? "เพิ่มกิจกรรมใหม่" : "รายละเอียดกิจกรรม",
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        if (widget.eventId != null)
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: _deleteEvent,
          )
        else
          const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildActivityImages(Color bg, Color iconCol) {
    List<Widget> imageWidgets = [];
    for (int i = 0; i < _existingImageUrls.length; i++) {
      imageWidgets.add(
        _buildImageThumbnail(
          imageProvider: NetworkImage(_existingImageUrls[i]),
          iconCol: iconCol,
          onRemove: () => _removeExistingImage(i),
        ),
      );
    }
    for (int i = 0; i < _selectedLocalImages.length; i++) {
      imageWidgets.add(
        _buildImageThumbnail(
          imageProvider: FileImage(_selectedLocalImages[i]),
          iconCol: iconCol,
          onRemove: () => _removeLocalImage(i),
        ),
      );
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
                  width: 75,
                  height: 75,
                  decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                  child: Icon(Icons.pets, color: iconCol, size: 40),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: iconCol, width: 1.5),
                  ),
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
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: imageWidgets,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "เดิน",
          style: GoogleFonts.inter(
            color: iconCol,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildImageThumbnail({
    required ImageProvider imageProvider,
    required Color iconCol,
    required VoidCallback onRemove,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: iconCol, width: 2),
              image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cancel,
                color: Colors.redAccent,
                size: 18,
              ),
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
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: GoogleFonts.inter(color: labelColor, fontSize: 14),
          ),
        ),
        Expanded(child: child),
      ],
    ),
  );

  Widget _buildInputBox(TextEditingController controller, String hint) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: TextField(
          controller: controller,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          decoration: InputDecoration(
            hintText: hint,
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          style: const TextStyle(fontSize: 14),
        ),
      );

  Widget _buildDivider() =>
      const Divider(height: 20, thickness: 1, color: Color(0xFFF0F0F0));

  Widget _buildPlainText(String t) =>
      Text(t, style: const TextStyle(fontSize: 14));

  Widget _buildTimePicker(BuildContext context) => InkWell(
    onTap: () async {
      final time = await showTimePicker(
        context: context,
        initialTime: _selectedTime,
      );
      if (time != null) setState(() => _selectedTime = time);
    },
    child: Text(
      "${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')} น.",
      style: const TextStyle(color: Colors.blue),
    ),
  );

  Widget _buildDurationPickerBtn(BuildContext context) => InkWell(
    onTap: () => showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => DurationPicker(
        initialDuration: _selectedDuration ?? Duration.zero,
        onDurationChanged: (d) => setState(() => _selectedDuration = d),
      ),
    ),
    child: Text(_formattedDuration, style: const TextStyle(color: Colors.blue)),
  );

  Widget _buildDistancePickerBtn(BuildContext context) => InkWell(
    onTap: () => showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => DistancePicker(
        initialDistanceKm: _selectedDistance ?? 0.0,
        onDistanceChanged: (v) => setState(() => _selectedDistance = v),
      ),
    ),
    child: Text(_formattedDistance, style: const TextStyle(color: Colors.blue)),
  );

  Widget _buildStickyBottomBar(Color col) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 15),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          height: 55,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: col,
              foregroundColor: Colors.black87,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: _saveToFirebase,
            icon: const Icon(Icons.check, size: 24),
            label: Text(
              widget.eventId == null ? "บันทึก" : "อัปเดต",
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
