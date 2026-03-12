import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:regdogapp/component/upperbar.dart';
import 'package:regdogapp/screen/dog_list.dart';

// 🌟 1. Import Component ที่เราสร้างไว้เข้ามา (เช็คที่อยู่โฟลเดอร์ให้ถูกต้อง)
import 'package:regdogapp/component/duration_picker.dart'; 
import 'package:regdogapp/component/distance_picker.dart';

class AddTrainEventPage extends StatefulWidget {
  const AddTrainEventPage({super.key});

  @override
  State<AddTrainEventPage> createState() => _AddWalkEventPageState();
}

class _AddWalkEventPageState extends State<AddTrainEventPage> {
  // 🌟 2. อัปเดตตัวแปรเก็บค่า
  TimeOfDay _selectedTime = const TimeOfDay(hour: 12, minute: 1);
  String _selectedReminder = "ทุกวัน";
  
  // เปลี่ยนจาก String เป็นประเภทที่ถูกต้อง และใช้ ? เพื่อให้เริ่มต้นเป็นค่าว่างได้
  Duration? _selectedDuration;
  double? _selectedDistance;

  // ฟังก์ชันช่วยจัดรูปแบบตัวอักษรของเวลาที่เลือก
  String get _formattedDuration {
    if (_selectedDuration == null) return "เลือกเวลา";
    String hours = _selectedDuration!.inHours.toString();
    String minutes = _selectedDuration!.inMinutes.remainder(60).toString().padLeft(2, '0');
    return "$hours:$minutes ชม.";
  }

  // ฟังก์ชันช่วยจัดรูปแบบตัวอักษรของระยะทางที่เลือก
  String get _formattedDistance {
    if (_selectedDistance == null) return "เลือกระยะทาง";
    return "${_selectedDistance!.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} กม.";
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF90C2D8); 
    const Color bgBlue = Color(0xFFE6F3FB); 
    const Color textLabelBlue = Color(0xFF6A97A8); 
    const Color yellowBtn = Color(0xFFFFEFA6); 

    return Scaffold(
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(0, 15, 0, 30),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(15, 15, 15, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // --- Header Row ---
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.black87),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                "เพิ่มกิจกรรมใหม่",
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 24), 
                        ],
                      ),
                      const SizedBox(height: 15), 

                      // --- Activity Icon ---
                      Container(
                        width: 80, 
                        height: 80,
                        decoration: const BoxDecoration(
                          color: bgBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.assignment,
                          color: primaryBlue,
                          size: 50, 
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "ฝึก",
                        style: GoogleFonts.inter(
                          fontSize: 16, 
                          fontWeight: FontWeight.w500,
                          color: primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 15), 

                      // --- Activity Info Card ---
                      Container(
                        padding: const EdgeInsets.all(15), 
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primaryBlue.withOpacity(0.5), width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                "ข้อมูลกิจกรรม",
                                style: GoogleFonts.inter(
                                  fontSize: 15, 
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10), 

                            // Form Fields
                            _buildFormRow("ชื่อ:", _buildInputBox("เดินเล่นหลังเลิกงาน"), textLabelBlue),
                            _buildDivider(),
                            
                            _buildFormRow("วัน:", _buildPlainText("23 พฤศจิกายน พ.ศ.2567"), textLabelBlue),
                            _buildDivider(),
                            
                            _buildFormRow("เวลา:", Row(
                              children: [
                                _buildTimePicker(context),
                                const SizedBox(width: 8),
                                const Text("น.", style: TextStyle(fontSize: 14)),
                              ],
                            ), textLabelBlue),
                            _buildDivider(),

                            // 🌟 3. เปลี่ยนมาใช้ปุ่มสำหรับเรียก Duration Picker
                            _buildFormRow("ระยะเวลา:", _buildDurationPickerBtn(context), textLabelBlue),
                            _buildDivider(),


                            _buildFormRow("โน้ต:", _buildInputBox("มีความสุขมากเลย"), textLabelBlue),
                            _buildDivider(),

                            _buildFormRow("แจ้งเตือน:", _buildActualDropdown(
                              _selectedReminder, 
                              ["ไม่เตือน", "ทุกวัน", "ทุกสัปดาห์"],
                              (val) => setState(() => _selectedReminder = val!),
                            ), textLabelBlue),
                            _buildDivider(),

                            _buildFormRow("วันที่สิ้นสุดการแจ้งเตือน:", _buildPlainText("25 พฤศจิกายน ค.ศ.2026"), textLabelBlue, labelFlex: 4),
                            _buildDivider(),

                            _buildFormRow("รูป:", Row(
                              children: [
                                _buildUploadButton(),
                                const SizedBox(width: 8),
                                Text(
                                  "1/4 (รูป) อัพโหลด",
                                  style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12),
                                )
                              ],
                            ), textLabelBlue),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 25), 

                      // --- Save Button ---
                      Align(
                        alignment: Alignment.centerRight,
                        child: Material(
                          color: yellowBtn,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              debugPrint("บันทึกข้อมูลเดิน - เวลา: $_formattedDuration, ระยะทาง: $_formattedDistance");
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10), 
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "บันทึก",
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.check, size: 18, color: Colors.black87),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // Helper Widgets 
  // ==========================================

  Widget _buildFormRow(String label, Widget child, Color labelColor, {int labelFlex = 2}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5), 
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Expanded(
            flex: labelFlex,
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0), 
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 16, 
                  color: labelColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(color: Colors.grey[200], height: 10, thickness: 1); 
  }

  Widget _buildPlainText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0), 
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
      ),
    );
  }

  Widget _buildInputBox(String hint) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        minLines: 1, 
        maxLines: null, 
        keyboardType: TextInputType.multiline, 
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.w400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), 
          isDense: true,
        ),
        style: GoogleFonts.inter(fontSize: 14),
      ),
    );
  }

  Widget _buildTimePicker(BuildContext context) {
    String formattedTime = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
    
    return InkWell(
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: _selectedTime,
        );
        if (picked != null && picked != _selectedTime) {
          setState(() {
            _selectedTime = picked;
          });
        }
      },
      child: Container(
        height: 32, 
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(formattedTime, style: GoogleFonts.inter(fontSize: 13, color: Colors.black87)),
            const SizedBox(width: 8),
            const Icon(Icons.access_time, color: Colors.black87, size: 16),
          ],
        ),
      ),
    );
  }

  // 🌟 ปุ่มเรียก Duration Picker
  Widget _buildDurationPickerBtn(BuildContext context) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => DurationPicker(
            initialDuration: _selectedDuration ?? const Duration(hours: 0, minutes: 0),
            onDurationChanged: (val) {
              setState(() {
                _selectedDuration = val;
              });
            },
          ),
        );
      },
      child: Container(
        height: 32, 
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_formattedDuration, style: GoogleFonts.inter(fontSize: 13, color: Colors.black87)),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down, color: Colors.black87, size: 16),
          ],
        ),
      ),
    );
  }

  // 🌟 ปุ่มเรียก Distance Picker
  Widget _buildDistancePickerBtn(BuildContext context) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => DistancePicker(
            initialDistanceKm: _selectedDistance ?? 0.0,
            onDistanceChanged: (val) {
              setState(() {
                _selectedDistance = val;
              });
            },
          ),
        );
      },
      child: Container(
        height: 32, 
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_formattedDistance, style: GoogleFonts.inter(fontSize: 13, color: Colors.black87)),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down, color: Colors.black87, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActualDropdown(String currentValue, List<String> options, ValueChanged<String?> onChanged) {
    return Container(
      height: 32, 
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black87, size: 16),
          isDense: true,
          style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
          onChanged: onChanged,
          items: options.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    return Container(
      height: 32, 
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("อัพโหลดไฟล์", style: GoogleFonts.inter(fontSize: 12, color: Colors.black87)),
          const SizedBox(width: 6),
          const Icon(Icons.upload_outlined, size: 14, color: Colors.black87),
        ],
      ),
    );
  }
}

  // 🌟 วิดเจ็ตใหม่: สำหรับ Dropdown ที่กดเลือกตัวเลือกได้จริง
  Widget _buildActualDropdown(String currentValue, List<String> options, ValueChanged<String?> onChanged) {
    return Container(
      height: 32, 
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black87, size: 16),
          isDense: true,
          style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
          onChanged: onChanged,
          items: options.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    return Container(
      height: 32, 
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("อัพโหลดไฟล์", style: GoogleFonts.inter(fontSize: 12, color: Colors.black87)),
          const SizedBox(width: 6),
          const Icon(Icons.upload_outlined, size: 14, color: Colors.black87),
        ],
      ),
    );
  }
