import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DurationPicker extends StatefulWidget {
  final Duration initialDuration;
  final ValueChanged<Duration> onDurationChanged;

  const DurationPicker({
    super.key,
    required this.initialDuration,
    required this.onDurationChanged,
  });

  @override
  State<DurationPicker> createState() => _DurationPickerState();
}

class _DurationPickerState extends State<DurationPicker> {
  late int _hours;
  late int _minutes;

  @override
  void initState() {
    super.initState();
    // ดึงค่าเริ่มต้นมาตั้งค่าให้ตัวเลื่อน (Picker)
    _hours = widget.initialDuration.inHours;
    _minutes = widget.initialDuration.inMinutes.remainder(60);
  }

  @override
  Widget build(BuildContext context) {
    // กำหนดสไตล์ตัวอักษรเพื่อความสะอาดตาและเรียกใช้ซ้ำได้ง่าย
    final labelStyle = GoogleFonts.poppins(
      fontSize: 16,
      color: Colors.black.withOpacity(0.8),
    );
    final pickerItemStyle = GoogleFonts.poppins(
      fontSize: 18,
      color: Colors.black.withOpacity(0.8),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      height: MediaQuery.of(context).size.height * 0.45, // ความสูงของ BottomSheet
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)), // ขอบมนด้านบน
      ),
      child: Column(
        children: [
          // แถบขีดสีเทาด้านบน (Drag Handle)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // หัวข้อ
          Text(
            'ระยะเวลา',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 20),
          
          // พื้นที่สำหรับเลื่อนเลือกเวลา (Pickers)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ---------------- เลือกชั่วโมง ----------------
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(initialItem: _hours),
                    itemExtent: 40,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _hours = index;
                      });
                    },
                    children: List.generate(
                      24, // 0 ถึง 23 ชั่วโมง
                      (index) => Center(
                        child: Text(index.toString(), style: pickerItemStyle),
                      ),
                    ),
                  ),
                ),
                Text('ชั่วโมง', style: labelStyle),
                const SizedBox(width: 10),
                
                // ---------------- เลือกนาที ----------------
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(initialItem: _minutes),
                    itemExtent: 40,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _minutes = index;
                      });
                    },
                    children: List.generate(
                      60, // 0 ถึง 59 นาที
                      (index) => Center(
                        child: Text(index.toString(), style: pickerItemStyle),
                      ),
                    ),
                  ),
                ),
                Text('นาที', style: labelStyle),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // ปุ่มยืนยัน (Set Button)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                // ส่งค่า Duration กลับไปยังหน้าที่เรียกใช้งาน
                widget.onDurationChanged(Duration(hours: _hours, minutes: _minutes));
                // ปิด BottomSheet
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFBE07B), // สีเหลืองตามภาพตัวอย่าง
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                'บันทึก',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF907238), // สีข้อความปุ่ม
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}