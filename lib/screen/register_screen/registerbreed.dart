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

  // 🟢 เพิ่ม Controller สำหรับรับค่าพิมพ์สายพันธุ์เอง
  final TextEditingController _customBreedController = TextEditingController();

  // 🟢 อัปเดตรายการสายพันธุ์สุนัขตามที่กำหนด
  final List<String> _dogBreeds = [
    'ปอมเมอเรเนียน',
    'ชิวาวา',
    'โกลเด้น รีทรีฟเวอร์',
    'พุดเดิ้ล',
    'ชิสุ',
    'ไซบีเรียน ฮัสกี้',
    'เฟรนช์ บูลด็อก',
    'บีเกิ้ล',
    'ลาบราดอร์ รีทรีฟเวอร์',
    'ไทยบางแก้ว',
    'อื่น ๆ', // ให้ 'อื่น ๆ' อยู่ล่างสุด
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
  void dispose() {
    // อย่าลืมเคลียร์หน่วยความจำของ Controller
    _customBreedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 🟢 แตะพื้นที่ว่างเพื่อซ่อนคีย์บอร์ด (มีประโยชน์เวลาพิมพ์สายพันธุ์เองเสร็จ)
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
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
                        padding: const EdgeInsets.symmetric(horizontal: 16), // เพิ่ม padding แนวนอนให้ฟอร์มดูสวยขึ้น
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
                                  padding: EdgeInsets.only(
                                    left: 20.0,
                                    right: 12.0,
                                  ),
                                  child: Icon(
                                    Icons.pets,
                                    color: _textLightBlue,
                                    size: 24,
                                  ),
                                ),
                                prefixIconConstraints: const BoxConstraints(
                                  minWidth: 0,
                                  minHeight: 0,
                                ),
                                suffixIcon: SizedBox(
                                  width: 64,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Container(
                                        width: 1.5,
                                        height: 24,
                                        color: _dividerColor,
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                      const SizedBox(width: 16),
                                    ],
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(50),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              items: _dogBreeds.map((String breed) {
                                return DropdownMenuItem<String>(
                                  value: breed,
                                  child: Text(
                                    breed,
                                    style: const TextStyle(color: _textDark),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedBreed = newValue;
                                  // หากเลือกเปลี่ยนสายพันธุ์ ให้ล้างค่าในช่องพิมพ์ที่เคยพิมพ์ไว้ (ถ้าต้องการ)
                                  if (newValue != 'อื่น ๆ') {
                                    _customBreedController.clear();
                                  }
                                });
                              },
                            ),

                            // 🟢 ถ้าเลือก "อื่น ๆ" ให้แสดงช่องกรอกข้อความ
                            if (_selectedBreed == 'อื่น ๆ') ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _customBreedController,
                                style: const TextStyle(color: _textDark),
                                decoration: InputDecoration(
                                  fillColor: Colors.white,
                                  filled: true,
                                  hintText: 'โปรดระบุสายพันธุ์',
                                  hintStyle: TextStyle(color: Colors.grey.shade400),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(50),
                                    borderSide: const BorderSide(color: _dropdownBg),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(50),
                                    borderSide: const BorderSide(color: _dropdownBg, width: 1.5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(50),
                                    borderSide: const BorderSide(color: _textLightBlue, width: 2),
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 30),

                            // --- 4. ปุ่ม ข้าม และ ต่อไป ---
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // ปุ่ม "ต่อไป"
                                SizedBox(
                                  height: 40,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      backgroundColor: _btnYellow,
                                      foregroundColor: Colors.black54,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                    ),
                                    onPressed: () async {
                                      // 1. เช็คว่าเลือกสายพันธุ์หรือยัง
                                      if (_selectedBreed == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('กรุณาเลือกสายพันธุ์น้องหมาด้วยนะคะ'),
                                          ),
                                        );
                                        return;
                                      }

                                      // 🟢 ตรวจสอบเพิ่มเติมหากเลือก "อื่น ๆ" แต่ไม่ได้พิมพ์อะไรลงไป
                                      String finalBreed = _selectedBreed!;
                                      if (_selectedBreed == 'อื่น ๆ') {
                                        if (_customBreedController.text.trim().isEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('กรุณาระบุสายพันธุ์ในช่องพิมพ์ด้วยนะคะ'),
                                            ),
                                          );
                                          return;
                                        }
                                        finalBreed = _customBreedController.text.trim();
                                      }

                                      // แสดง Loading
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (context) => const Center(
                                          child: CircularProgressIndicator(
                                            color: _btnYellow,
                                          ),
                                        ),
                                      );

                                      try {
                                        // 2. แปลง String เป็น DateTime
                                        DateTime parsedBirthDate = _parseDate(
                                          widget.dogBirthdate,
                                        );

                                        // 3. 🐾 เรียกใช้ DatabaseService แทนการยิงตรงๆ 🐾
                                        bool isSuccess = await DatabaseService()
                                            .addDog(
                                              name: widget.dogName,
                                              gender: widget.dogGender,
                                              breed: finalBreed, // 🟢 ส่ง finalBreed ไปบันทึก
                                              birthDate: parsedBirthDate,
                                            );

                                        // ปิด Loading
                                        if (!mounted) return;
                                        Navigator.pop(context);

                                        if (isSuccess) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('บันทึกข้อมูลน้องหมาสำเร็จแล้ว!'),
                                            ),
                                          );
                                          // TODO: ย้ายไปหน้าถัดไป
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const DogListPage(),
                                            ),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('เกิดข้อผิดพลาดในการบันทึกฐานข้อมูล'),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        Navigator.pop(context);
                                        debugPrint("Error saving dog: $e");
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('เกิดข้อผิดพลาด: $e'),
                                          ),
                                        );
                                      }
                                    },
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'บันทึก',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: _textDark,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_forward,
                                          size: 20,
                                          color: _textDark,
                                        ),
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
      ),
    );
  }
}