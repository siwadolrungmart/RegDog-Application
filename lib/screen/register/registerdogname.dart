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
          // --- 1. เลเยอร์ Background ---
          Positioned.fill(
            child: Image.asset(
              'assets/bg_watercolor.png', 
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                 debugPrint("Error loading background image: $error");
                 return Container(color: Colors.white);
              }, 
            ),
          ),

          // --- 2. เลเยอร์ Content หลัก ---
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ปุ่ม Back Arrow ด้านบนซ้าย
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 8.0),
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
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          
                          // รูปการ์ตูนสุนัข
                          Image.asset(
                            'assets/dog-ping.png',
                            width: 200,
                            height: 200,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => 
                                const Icon(Icons.pets, size: 150, color: Colors.grey),
                          ),
                          const SizedBox(height: 32),

                          // ข้อความ "ชื่อสุนัขของคุณ"
                          const Text(
                            'ชื่อสุนัขของคุณ',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: _textDark,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // --- ช่องกรอกชื่อสุนัข ---
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
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
                                hintStyle: const TextStyle(color: Colors.black38),
                                prefixIcon: const Icon(Icons.pets, color: Colors.black26, size: 22),
                                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: _borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: _btnYellow, width: 2),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // --- กลุ่มปุ่ม "ข้าม" และ "ต่อไป" ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // ปุ่ม "ข้าม"
                              SizedBox(
                                height: 48,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(color: _btnYellow, width: 1.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: () {
                                    // TODO: ใส่ Logic สำหรับการกดข้าม
                                     Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Registergender(),
                          ),
                        );
                                  },
                                  child: const Text(
                                    'ข้าม',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: _textDark,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              
                              // ปุ่ม "ต่อไป"
                              SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _btnYellow,
                                    foregroundColor: Colors.black54, // สีเอฟเฟกต์ตอนกด
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
                            builder: (context) => const Registergender(),
                          ),
                        );
                                    print("ชื่อน้องหมาคือ: ${_dogNameController.text}");
                                  },
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'ต่อไป',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
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