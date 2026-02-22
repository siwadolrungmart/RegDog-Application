import 'package:flutter/material.dart';
import 'package:regdogapp/screen/register/registerdogname.dart';

class Registerhavedog extends StatelessWidget {
  const Registerhavedog({super.key});

  // กำหนดสี Constants เพื่อความ Clean และนำไปใช้ซ้ำได้ง่าย
  static const Color _primaryPastelBlue = Color(0xFFBCE6EB);
  static const Color _textDark = Color(0xFF212121);
  static const Color _textLightBlue = Color(0xFF86BCC6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // เปลี่ยนสีพื้นหลัง Scaffold เป็น transparent เพื่อให้เห็นรูปข้างหลังชัดเจน
      // backgroundColor: Colors.transparent, 
      body: Stack(
        children: [
          // --- 1. เลเยอร์ Background (แก้ไขใหม่) ---
          // Positioned.fill(
          //   child: Image.asset(
          //     // เปลี่ยน path ตรงนี้เป็นรูปที่คุณต้องการ
          //     'assets/bg_watercolor.png', 
          //     fit: BoxFit.cover, // ขยายเต็มจอโดยไม่เสียสัดส่วน
          //     // Fallback สีขาวกรณีที่ยังไม่ได้ใส่รูปภาพเข้าโปรเจกต์ หรือ path ผิด
          //     errorBuilder: (context, error, stackTrace) {
          //        debugPrint("Error loading background image: $error");
          //        return Container(color: Colors.white);
          //     }, 
          //   ),
          // ),

          // --- 2. เลเยอร์ Content หลัก ---
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ปุ่ม Back Arrow ด้านบนซ้าย
                Padding(
                  padding: const EdgeInsets.only(left: 0, top: 0),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: _textDark),
                    onPressed: () {
                      // Logic การย้อนกลับ
                      Navigator.pop(context);
                    },
                  ),
                ),

                // ส่วนเนื้อหาที่ Scroll ได้ (ป้องกัน Overflow)
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0.0),
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
                                const Icon(Icons.pets, size: 150, color: Colors.grey),
                          ),
                          const SizedBox(height: 18),

                          // ข้อความ "คุณมีสุนัขหรือไม่"
                          const Text(
                            'คุณมีสุนัขหรือไม่',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              color: _textDark,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // ปุ่มที่ 1: ฉันมีสุนัข (Outline)
                          SizedBox(
                            width: double.infinity,
                            height: 45, // ความสูงมาตรฐานเพื่อให้กดง่าย
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.8), // เพิ่มความโปร่งใสให้ปุ่มนิดหน่อยเพื่อให้เข้ากับพื้นหลัง
                                side: const BorderSide(
                                  color: _primaryPastelBlue, 
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () {
                                // TODO: ใส่ Logic สำหรับผู้ที่มีสุนัข
                                 Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Registerdogname(),
                          ),
                        );
                              },
                              child: const Text(
                                'ฉันมีสุนัข',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: _textLightBlue,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ปุ่มที่ 2: ฉันไม่มีสุนัข (Filled)
                          SizedBox(
                            width: double.infinity,
                            height: 45, // ความสูงมาตรฐานเพื่อให้กดง่าย
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.8), // เพิ่มความโปร่งใสให้ปุ่มนิดหน่อยเพื่อให้เข้ากับพื้นหลัง
                                side: const BorderSide(
                                  color: _primaryPastelBlue, 
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () {
                                // TODO: ใส่ Logic สำหรับผู้ที่มีสุนัข
                                 Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Registerdogname(),
                          ),
                        );
                              },
                              child: const Text(
                                'ฉันไม่มีสุนัข',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: _textLightBlue,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Bottom Padding เผื่อสำหรับจอที่มีขอบล่าง
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