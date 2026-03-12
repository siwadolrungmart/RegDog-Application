import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DistancePicker extends StatefulWidget {
  final double initialDistanceKm;
  final ValueChanged<double> onDistanceChanged;

  const DistancePicker({
    super.key,
    required this.initialDistanceKm,
    required this.onDistanceChanged,
  });

  @override
  State<DistancePicker> createState() => _DistancePickerState();
}

class _DistancePickerState extends State<DistancePicker> {
  late int _km;
  late int _metersIndex; // เก็บเป็น index ของลิสต์ (0-19) แทนค่าเมตรตรงๆ

  @override
  void initState() {
    super.initState();
    // แยกค่ากิโลเมตร
    _km = widget.initialDistanceKm.toInt();
    
    // แยกค่าเมตร และแปลงให้เป็น index (เนื่องจากเรากระโดดทีละ 50 เมตร)
    // ใช้ .round() เพื่อป้องกันปัญหาเศษทศนิยมของ double
    int actualMeters = ((widget.initialDistanceKm - _km) * 1000).round();
    _metersIndex = actualMeters ~/ 50; // หารเอาส่วน เพื่อให้ได้ index เช่น 500m -> index 10
  }

  @override
  Widget build(BuildContext context) {
    // กำหนดสไตล์ตัวอักษร
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
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
            'ระยะทาง',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 20),
          
          // พื้นที่สำหรับเลื่อนเลือกระยะทาง
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ---------------- เลือกกิโลเมตร ----------------
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(initialItem: _km),
                    itemExtent: 40,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _km = index;
                      });
                    },
                    children: List.generate(
                      100, // 0 ถึง 99 กิโลเมตร (ปรับเพิ่มได้ถ้าต้องการ)
                      (index) => Center(
                        child: Text(index.toString(), style: pickerItemStyle),
                      ),
                    ),
                  ),
                ),
                Text('กิโลเมตร', style: labelStyle),
                const SizedBox(width: 10),
                
                // ---------------- เลือกเมตร (ทีละ 50) ----------------
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(initialItem: _metersIndex),
                    itemExtent: 40,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _metersIndex = index;
                      });
                    },
                    children: List.generate(
                      20, // 20 รายการ (20 * 50 = 1000 เมตร)
                      (index) => Center(
                        // นำ index มาคูณ 50 เพื่อแสดงผลเป็น 0, 50, 100, 150...
                        child: Text((index * 50).toString(), style: pickerItemStyle),
                      ),
                    ),
                  ),
                ),
                Text('เมตร', style: labelStyle),
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
                // คำนวณระยะทางรวมกลับเป็นทศนิยม (กิโลเมตร)
                // แปลง index กลับเป็นเมตรโดยคูณ 50 แล้วหาร 1000 เพื่อเป็นกิโลเมตร
                double distanceKm = _km + ((_metersIndex * 50) / 1000);
                
                // ส่งค่ากลับไป
                widget.onDistanceChanged(distanceKm);
                
                // ปิด BottomSheet
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFBE07B),
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
                  color: const Color(0xFF907238),
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