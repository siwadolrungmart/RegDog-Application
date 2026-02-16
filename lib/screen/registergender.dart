import 'package:flutter/material.dart';
import 'package:regdogapp/screen/registerbirthday.dart';
// TODO: อย่าลืม Import ไฟล์ Registerhavedog ของคุณไว้ด้านบนสุดด้วยนะครับ
// import 'package:regdogapp/screen/registerhavedog.dart'; 

class Registergender extends StatefulWidget {
  const Registergender({super.key});

  @override
  State<Registergender> createState() => _RegistergenderState();
}

class _RegistergenderState extends State<Registergender> {
  // ตัวแปรเก็บสถานะว่าผู้ใช้เลือกเพศอะไร (null = ยังไม่เลือก, 'male' = ผู้, 'female' = เมีย)
  String? _selectedGender;

  // กำหนดโทนสี Constants ให้อ้างอิงง่ายและโค้ด Clean
  static const Color _textDark = Color(0xFF212121);
  static const Color _textLightBlue = Color(0xFF6B9BA3); // สีฟ้าเข้มสำหรับตัวหนังสือ
  static const Color _borderColor = Color(0xFFBCE6EB); // สีขอบฟ้าอ่อน
  static const Color _bgPastelBlue = Color(0xFFC4E8EE); // สีพื้นปุ่มเพศเมีย

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // โปร่งใสเพื่อโชว์พื้นหลัง
      body: Stack(
        children: [
          // --- 1. เลเยอร์ Background ลาย Pastel Brush ---
          Positioned.fill(
            child: Image.asset(
              'assets/bg_watercolor.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: Colors.white), // Fallback สีขาว
            ),
          ),

          // --- 2. เลเยอร์ Content หลัก ---
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ส่วนปุ่ม Back Arrow สีดำ มุมซ้ายบน
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: _textDark),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),

                // ส่วนเนื้อหาที่ Scroll ได้ + จัดกึ่งกลาง
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 30),

                          // รูปการ์ตูนสุนัขตรงกลาง
                          Image.asset(
                            'assets/dog-ping.png',
                            width: 200,
                            height: 200,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.pets, size: 150, color: Colors.grey),
                          ),
                          const SizedBox(height: 24),

                          // ข้อความหัวข้อ
                          const Text(
                            'เพศสุนัขของคุณ',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              fontSize: 22,
                              color: _textDark,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // --- 3. ส่วนปุ่มเลือกเพศ (Row) ---
                          Row(
                            children: [
                              // ปุ่มซ้าย: เพศผู้
                              Expanded(
                                child: _buildGenderButton(
                                  title: 'เพศผู้',
                                  value: 'male',
                                  defaultBgColor: Colors.white,
                                  defaultTextColor: _textLightBlue,
                                  defaultBorderColor: _borderColor,
                                ),
                              ),
                              const SizedBox(width: 16), // ระยะห่าง 16px ตาม requirement
                              
                              // ปุ่มขวา: เพศเมีย
                              Expanded(
                                child: _buildGenderButton(
                                  title: 'เพศเมีย',
                                  value: 'female',
                                  defaultBgColor: Colors.white,
                                  defaultTextColor: _textLightBlue,
                                  defaultBorderColor: _borderColor, 
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

  // --- Widget แยกสำหรับสร้างปุ่ม เพื่อลดโค้ดซ้ำซ้อน ---
  Widget _buildGenderButton({
    required String title,
    required String value,
    required Color defaultBgColor,
    required Color defaultTextColor,
    required Color defaultBorderColor,
  }) {
    // เช็คว่าปุ่มนี้ถูกเลือกอยู่หรือไม่
    bool isSelected = _selectedGender == value;
    
    // Logic การเปลี่ยนสี (Highlight): 
    Color currentBgColor = isSelected ? defaultBgColor : defaultBgColor.withOpacity(0.6);
    Color currentBorderColor = isSelected ? _textLightBlue : defaultBorderColor;
    double elevation = isSelected ? 8.0 : 0.0;

    return GestureDetector(
      onTap: () {
        // 1. เปลี่ยนสถานะปุ่มให้โชว์สีเข้มขึ้น
        setState(() {
          _selectedGender = value;
        });
        
        debugPrint("ผู้ใช้เลือกเพศ: $value");

        // 2. หน่วงเวลา 0.3 วินาที ให้เห็นแอนิเมชันปุ่มสว่างขึ้น แล้วค่อยเปลี่ยนหน้า
        Future.delayed(const Duration(milliseconds: 300), () {
          // ตรวจสอบความปลอดภัยว่าหน้าจอยังเปิดอยู่หรือไม่ก่อนเปลี่ยนหน้า
          if (!context.mounted) return; 

          // 3. เปลี่ยนหน้าไปยัง Registerhavedog
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              // อย่าลืมตรวจสอบชื่อ Class ปลายทางให้ตรงกับไฟล์ของคุณนะครับ
              builder: (context) => const Registerbirthday(), 
            ),
          );
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250), // ความเร็วในการเปลี่ยนสี
        curve: Curves.easeInOut,
        height: 56, // ความสูงปุ่มให้กดง่าย
        decoration: BoxDecoration(
          color: currentBgColor,
          borderRadius: BorderRadius.circular(50), // มุมโค้งมนทรง Pill
          border: Border.all(
            color: currentBorderColor,
            width: isSelected ? 2.0 : 1.5, // ขอบหนาขึ้นนิดนึงตอนเลือก
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(elevation * 0.01),
              blurRadius: elevation,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: isSelected ? _textDark : defaultTextColor.withOpacity(0.8), 
          ),
        ),
      ),
    );
  }
}