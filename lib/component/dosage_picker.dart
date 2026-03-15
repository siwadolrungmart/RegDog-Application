import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class DosagePicker extends StatefulWidget {
  final String initialAmount;
  final String initialUnit;
  final Function(String amount, String unit) onDosageChanged;

  const DosagePicker({
    super.key,
    this.initialAmount = '',
    this.initialUnit = 'เม็ด', // ค่าเริ่มต้น
    required this.onDosageChanged,
  });

  @override
  State<DosagePicker> createState() => _DosagePickerState();
}

class _DosagePickerState extends State<DosagePicker> {
  late TextEditingController _amountController;
  late int _selectedUnitIndex;

  // รายการหน่วยยาที่แปลเป็นไทยแล้ว
  final List<String> _units = [
    'มิลลิกรัม (mg)',
    'มิลลิลิตร (ml)',
    'หยด',
    'เม็ด',
    'หลอด (ครีม)',
    'เข็ม (ฉีด)',
    'ซอง (ผง)',
    'ไม่ระบุ'
  ];

  @override
  void initState() {
    super.initState();
    // ตั้งค่าเริ่มต้นให้กับช่องกรอก
    _amountController = TextEditingController(text: widget.initialAmount);
    
    // หา index ของหน่วยเริ่มต้น ถ้าไม่เจอให้เป็น 0
    _selectedUnitIndex = _units.indexOf(widget.initialUnit);
    if (_selectedUnitIndex == -1) {
      _selectedUnitIndex = 3; // ค่า default ให้ตกที่ 'เม็ด'
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.black.withOpacity(0.8),
    );
    final pickerItemStyle = GoogleFonts.poppins(
      fontSize: 16,
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
          Text('ปริมาณยา', style: titleStyle),
          const SizedBox(height: 20),
          
          // พื้นที่สำหรับกรอกปริมาณและเลือกหน่วย
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ---------------- ด้านซ้าย: ช่องกรอกตัวเลข ----------------
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        labelText: 'ระบุปริมาณ',
                        labelStyle: GoogleFonts.poppins(fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: Color(0xFFADD8FF)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: Color(0xFF90C2D8), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      // บังคับให้พิมพ์ได้เฉพาะตัวเลขและจุดทศนิยม
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                    ),
                  ),
                ),
                
                // ---------------- ด้านขวา: เลือกหน่วยยา ----------------
                Expanded(
                  flex: 1,
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(initialItem: _selectedUnitIndex),
                    itemExtent: 40,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _selectedUnitIndex = index;
                      });
                    },
                    children: List.generate(
                      _units.length,
                      (index) => Center(
                        child: Text(_units[index], style: pickerItemStyle),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          
          // ปุ่มยืนยัน (Set Button)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                // ดึงค่าจาก TextField และ Picker
                String enteredAmount = _amountController.text.trim();
                String selectedUnit = _units[_selectedUnitIndex];
                
                // ส่งค่ากลับไป
                widget.onDosageChanged(enteredAmount, selectedUnit);
                
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