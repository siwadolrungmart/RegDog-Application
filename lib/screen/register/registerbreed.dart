import 'package:flutter/material.dart';
import 'package:regdogapp/component/bar.dart';

class Registerbreed extends StatefulWidget {
  const Registerbreed({super.key});

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
  static const Color _textLightBlue = Color(0xFF6B9BA3); // สีข้อความใน Dropdown
  static const Color _btnYellow = Color(0xFFFEF0B3);
  static const Color _dropdownBg = Color(
    0xFFBCE6EB,
  ); // สีพื้นหลัง Dropdown (ฟ้าพาสเทล)
  static const Color _dividerColor = Color(0xFF212121); // สีเส้นคั่น (ดำ)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _currentIndex,
        onItemTapped: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
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
                      Navigator.pop(context); // TODO: Logic ย้อนกลับ
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
                            'assets/dog-ping.png', // ตรวจสอบ path รูปให้ถูกต้อง
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

                          // --- 3. ช่องเลือกสายพันธุ์ (ใช้ M3 DropdownButtonFormField ล้วนๆ) ---
                          DropdownButtonFormField<String>(
                            value: _selectedBreed,
                            isExpanded:
                                true, // ป้องกันปัญหา Text ยาวเกินแล้วพัง
                            // ซ่อนไอคอนลูกศรเดิมของระบบ
                            icon: const SizedBox.shrink(),
                            style: const TextStyle(
                              fontSize: 16,
                              color: _textLightBlue, // สีข้อความเมื่อเลือกแล้ว
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              fillColor: _dropdownBg, // สีฟ้าพาสเทล
                              filled: true,
                              hintText: 'สายพันธุ์',
                              hintStyle: TextStyle(
                                color: _textLightBlue.withOpacity(0.7),
                              ),

                              // --- จัดการไอคอนด้านซ้าย (หน้าสุนัข) ---
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

                              // --- จัดการส่วนด้านขวา (เส้นคั่น + ลูกศร) ---
                              suffixIcon: SizedBox(
                                width: 64, // กำหนดพื้นที่ให้พอดีกับเส้นและไอคอน
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // เส้นคั่น
                                    Container(
                                      width: 1.5,
                                      height: 24,
                                      color: _dividerColor, // สีดำ
                                    ),
                                    const SizedBox(width: 8),
                                    // ไอคอนลูกศร
                                    const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                    const SizedBox(width: 16),
                                  ],
                                ),
                              ),

                              // --- จัดการขอบโค้งแบบ Pill ---
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                                borderSide: BorderSide.none,
                              ),
                            ),

                            // ข้อมูลใน Dropdown
                            items: _dogBreeds.map((String breed) {
                              return DropdownMenuItem<String>(
                                value: breed,
                                child: Text(
                                  breed,
                                  style: const TextStyle(
                                    color: _textDark,
                                  ), // สีตัวเลือกเป็นสีดำให้อ่านง่ายตอนกดเด้งขึ้นมา
                                ),
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
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    backgroundColor: Colors.white.withOpacity(
                                      0.5,
                                    ),
                                    side: const BorderSide(
                                      color: _btnYellow,
                                      width: 2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: () {
                                    // TODO: ใส่ Logic ข้าม
                                    debugPrint("กดข้าม");
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
                              const SizedBox(width: 10),

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
                                  onPressed: () {
                                    // TODO: ส่งค่าสายพันธุ์ไปหน้าถัดไป
                                    debugPrint(
                                      "สายพันธุ์ที่เลือก: $_selectedBreed",
                                    );
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
    );
  }
}
