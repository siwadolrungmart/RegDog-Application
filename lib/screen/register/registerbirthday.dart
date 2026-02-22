import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Registerbirthday extends StatefulWidget {
  const Registerbirthday({super.key});

  @override
  State<Registerbirthday> createState() => _RegisterbirthdayState();
}

class _RegisterbirthdayState extends State<Registerbirthday> {
  // Controller สำหรับช่องกรอกวันที่
  final TextEditingController _dateController = TextEditingController();
  // ตัวแปรเก็บค่าวันที่ที่เลือก (เผื่อใช้ส่งเข้า Database)
  DateTime? _selectedDate;

  // กำหนดสี Constants
  static const Color _textDark = Color(0xFF212121);
  static const Color _btnYellow = Color(0xFFFEF0B3);
  static const Color _borderColor = Color(0xFFE0E0E0);

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  // ฟังก์ชันเปิด DatePicker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('th', 'TH'), // ปฏิทินภาษาไทย
      
      // 🌟 1. บังคับให้ใช้โหมดปฏิทินเท่านั้น (ซ่อนไอคอนปากกา)
      initialEntryMode: DatePickerEntryMode.calendarOnly, 
      
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFDE894), // สี Header (เหลืองพาสเทล)
              onPrimary: _textDark,       // สีตัวอักษรบน Header
              onSurface: _textDark,       // สีตัวเลขวันที่ในปฏิทิน
            ),
            
            // 🌟 2. เปลี่ยนสีปุ่ม "ตกลง" (OK) และ "ยกเลิก" (Cancel) เป็นสีดำ
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black, // กำหนดสีตัวอักษรปุ่มที่นี่
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600, // ปรับให้ตัวหนาขึ้นนิดนึงให้อ่านง่าย
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    // ถ้ายืนยันการเลือกวันที่ ให้อัปเดตค่าในช่อง TextField
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // Format เป็น dd/MM/yyyy ภาษาไทย (เช่น 17/08/2568)
        _dateController.text = DateFormat('dd/MM/yyyy', 'th_TH').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // โปร่งใสเพื่อใช้พื้นหลัง Stack
      body: Stack(
        children: [
          
          // --- 2. เลเยอร์ Content หลัก ---
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ปุ่ม Back Arrow
                Padding(
                  padding: const EdgeInsets.only(left: 0, top: 0),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: _textDark),
                    onPressed: () {
                      Navigator.pop(context); // TODO: Logic การย้อนกลับ
                    },
                  ),
                ),

                // เนื้อหาที่ Scroll ได้
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 30),

                          // รูปการ์ตูนสุนัข
                          Image.asset(
                            'assets/dog-ping.png', // เปลี่ยน path รูปให้ถูกต้อง
                            width: 200,
                            height: 200,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.pets, size: 150, color: Colors.black12),
                          ),
                          const SizedBox(height: 18),

                          // ข้อความหัวข้อ
                          const Text(
                            'วันเกิดสุนัขของคุณ',
                            style: TextStyle(
                              fontFamily: 'Inter', // ตาม requirement
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              color: _textDark,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // --- ช่องเลือกวันที่ (TextField) ---
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: TextField(
                              controller: _dateController,
                              readOnly: true, // ทำให้พิมพ์เองไม่ได้ ต้องจิ้มเลือกปฏิทินเท่านั้น
                              onTap: () => _selectDate(context), // เด้ง DatePicker เมื่อกด
                              style: const TextStyle(
                                fontSize: 16,
                                color: _textDark,
                              ),
                              decoration: InputDecoration(
                                hintText: 'วัน/เดือน/ปี',
                                hintStyle: const TextStyle(color: Colors.black38),
                                suffixIcon: const Icon(Icons.calendar_month, color: Colors.black54),
                                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: _borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: _textDark, width: 1.5),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // --- ปุ่ม "ข้าม" และ "ต่อไป" (Row ชิดขวา) ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // ปุ่ม ข้าม
                              SizedBox(
                                height: 40,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(color: _btnYellow, width: 1.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: () {
                                    // TODO: ใส่ Logic ข้าม
                                    debugPrint("ข้ามหน้าวันเกิด");
                                  },
                                  child: const Text(
                                    'ข้าม',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: _textDark,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10), // ระยะห่างระหว่างปุ่ม

                              // ปุ่ม ต่อไป
                              SizedBox(
                                height: 40,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    backgroundColor: _btnYellow,
                                    foregroundColor: Colors.black54, // เอฟเฟกต์สีตอนกด
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                  onPressed: () {
                                    // TODO: ส่งค่าวันเกิดไปหน้าถัดไป
                                    debugPrint("วันเกิดที่เลือก: ${_dateController.text}");
                                  },
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'ต่อไป',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: _textDark,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(Icons.arrow_forward, size: 20, color: _textDark),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}