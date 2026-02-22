import 'package:flutter/material.dart';
import 'package:regdogapp/screen/register/registergender.dart';

class Registerdogname extends StatefulWidget {
  const Registerdogname({super.key});

  @override
  State<Registerdogname> createState() => _RegisterdognameState();
}

class _RegisterdognameState extends State<Registerdogname> {
  // สร้าง Controller เพื่อรอรับค่าชื่อน้องหมา
  final TextEditingController _dogNameController = TextEditingController();

  // กำหนดสี Constants
  static const Color _textDark = Color(0xFF212121);
  static const Color _btnYellow = Color(0xFFFEF0B3); // สีเหลืองทองแบบในรูป
  static const Color _borderColor = Color(0xFFE0E0E0);

  @override
  void dispose() {
    _dogNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
    
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
                      Navigator.pop(context);
                    },
                  ),
                ),

                // ส่วนเนื้อหาที่ Scroll ได้
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
                                  color: Colors.grey,
                                ),
                          ),
                          const SizedBox(height: 18),

                          // ข้อความ "ชื่อสุนัขของคุณ"
                          const Text(
                            'ชื่อสุนัขของคุณ',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              color: _textDark,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // --- ช่องกรอกชื่อสุนัข ---
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextField(
                              
                              controller: _dogNameController,

                              decoration: InputDecoration(
                                hintText: 'ชื่อ',
                                hintStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black38,
                                ),
                                prefixIcon: const Icon(
                                  Icons.pets,
                                  color: Colors.black26,
                                  size: 24,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 12,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: _borderColor,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: _btnYellow,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // --- กลุ่มปุ่ม "ข้าม" และ "ต่อไป" ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // ปุ่ม "ข้าม"
                              SizedBox(
                                height: 40,
                                
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: _btnYellow,
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: () {
                                    // TODO: ใส่ Logic สำหรับการกดข้าม
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const Registergender(),
                                      ),
                                    );
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
                              const SizedBox(width: 5),

                              // ปุ่ม "ต่อไป"
                              SizedBox(
                                height: 40,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    backgroundColor: _btnYellow,
                                    foregroundColor:
                                        Colors.black54, // สีเอฟเฟกต์ตอนกด
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                  onPressed: () {
                                    // TODO: ส่งค่าชื่อน้องหมาไปหน้าถัดไป
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const Registergender(),
                                      ),
                                    );
                                    print(
                                      "ชื่อน้องหมาคือ: ${_dogNameController.text}",
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
