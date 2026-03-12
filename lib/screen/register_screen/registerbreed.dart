import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:regdogapp/component/bar.dart';
import 'package:regdogapp/screen/dog_list.dart';
import 'package:regdogapp/service/dogdatabase_service.dart';
// TODO: อย่าลืม Import ไฟล์ DatabaseService ของคุณเข้ามาด้วยนะครับ
// import 'path_to_your_file/database_service.dart'; 

class Registerbreed extends StatefulWidget {
  final String dogName;
  final String dogGender;
  final String dogBirthdate; // สมมติว่ามาในรูปแบบ "DD/MM/YYYY" เช่น "01/03/2026"

  const Registerbreed({
    super.key,
    required this.dogName,
    required this.dogGender,
    required this.dogBirthdate,
  });

  @override
  State<Registerbreed> createState() => _RegisterbreedState();
}

class _RegisterbreedState extends State<Registerbreed> {
  // ตัวแปรเก็บสายพันธุ์ที่เลือก
  String? _selectedBreed;
  int _currentIndex = 2; // ตั้งค่าเริ่มต้นที่ 2 (หน้าแรก)
  
  // รายการสายพันธุ์สุนัข
  final List<String> _dogBreeds = [
    'ปอมเมอเรเนียน',
    'ชิวาวา',
    'โกลเด้น รีทรีฟเวอร์',
    'ลาบราดอร์',
    'ไทยหลังอาน',
    'อื่น ๆ',
  ];

  // สี Constants ตาม Design
  static const Color _bgOffWhite = Color(0xFFF6F6F6);
  static const Color _textDark = Color(0xFF212121);
  static const Color _textLightBlue = Color(0xFF6B9BA3); 
  static const Color _btnYellow = Color(0xFFFEF0B3);
  static const Color _dropdownBg = Color(0xFFBCE6EB); 
  static const Color _dividerColor = Color(0xFF212121); 

  // ฟังก์ชันแปลง String เป็น DateTime
  DateTime _parseDate(String dateStr) {
    try {
      // สมมติว่า dateStr คือ "01/03/2026" (วัน/เดือน/ปี)
      List<String> parts = dateStr.split('/');
      if (parts.length == 3) {
        int day = int.parse(parts[0]);
        int month = int.parse(parts[1]);
        int year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
      return DateTime.now(); // ถ้า Format ผิดพลาด ให้ใช้วันนี้แทน
    } catch (e) {
      return DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      Navigator.pop(context); 
                    },
                  ),
                ),

                // เนื้อหาหลักที่ Scroll ได้
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
                            'assets/dog-ping.png', 
                            width: 200,
                            height: 200,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.pets,
                                  size: 150,
                                  color: Colors.black12,
                                ),
                          ),
                          const SizedBox(height: 18),

                          // ข้อความหัวข้อ
                          const Text(
                            'สายพันธุ์สุนัขของคุณ',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              color: _textDark,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // --- 3. ช่องเลือกสายพันธุ์ ---
                          DropdownButtonFormField<String>(
                            value: _selectedBreed,
                            isExpanded: true, 
                            icon: const SizedBox.shrink(),
                            style: const TextStyle(
                              fontSize: 16,
                              color: _textLightBlue, 
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              fillColor: _dropdownBg, 
                              filled: true,
                              hintText: 'สายพันธุ์',
                              hintStyle: TextStyle(
                                color: _textLightBlue.withOpacity(0.7),
                              ),
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(left: 20.0, right: 12.0),
                                child: Icon(Icons.pets, color: _textLightBlue, size: 24),
                              ),
                              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                              suffixIcon: SizedBox(
                                width: 64, 
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(width: 1.5, height: 24, color: _dividerColor),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
                                    const SizedBox(width: 16),
                                  ],
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: _dogBreeds.map((String breed) {
                              return DropdownMenuItem<String>(
                                value: breed,
                                child: Text(breed, style: const TextStyle(color: _textDark)),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedBreed = newValue;
                              });
                            },
                          ),

                          const SizedBox(height: 10),

                          // --- 4. ปุ่ม ข้าม และ ต่อไป ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // ปุ่ม "ข้าม"
                              SizedBox(
                                height: 40,
                               
                              ),
                              const SizedBox(width: 10),

                              // ปุ่ม "ต่อไป"
                              SizedBox(
                                height: 40,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    backgroundColor: _btnYellow,
                                    foregroundColor: Colors.black54,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  ),
                                  onPressed: () async {
                                    // 1. เช็คว่าเลือกสายพันธุ์หรือยัง
                                    if (_selectedBreed == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('กรุณาเลือกสายพันธุ์น้องหมาด้วยนะคะ')),
                                      );
                                      return;
                                    }

                                    // แสดง Loading 
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (context) => const Center(
                                        child: CircularProgressIndicator(color: _btnYellow),
                                      ),
                                    );

                                    try {
                                      // 2. แปลง String เป็น DateTime
                                      DateTime parsedBirthDate = _parseDate(widget.dogBirthdate);

                                      // 3. 🐾 เรียกใช้ DatabaseService แทนการยิงตรงๆ 🐾
                                      // ต้องแน่ใจว่า import class DatabaseService มาแล้วด้านบน
                                      bool isSuccess = await DatabaseService().addDog(
                                        name: widget.dogName,
                                        gender: widget.dogGender,
                                        breed: _selectedBreed!,
                                        birthDate: parsedBirthDate,
                                      );

                                      // ปิด Loading
                                      if (!mounted) return;
                                      Navigator.pop(context);

                                      if (isSuccess) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('บันทึกข้อมูลน้องหมาสำเร็จแล้ว!')),
                                        );
                                        // TODO: ย้ายไปหน้าถัดไป
                                         Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DogListPage(), // เปลี่ยนเป็นชื่อคลาสหน้าเพิ่มสุนัขของคุณ
          ),
        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกฐานข้อมูล')),
                                        );
                                      }

                                    } catch (e) {
                                      Navigator.pop(context);
                                      debugPrint("Error saving dog: $e");
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                                      );
                                    }
                                  },
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'บันทึก',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _textDark),
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