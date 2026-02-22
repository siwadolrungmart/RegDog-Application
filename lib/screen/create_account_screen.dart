// 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:regdogapp/screen/login_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // ใช้จัดการการตรวจสอบข้อมูลในฟอร์ม

  // ฟังก์ชันสมัครสมาชิก
  Future<void> _register() async {
    // 1. ตรวจสอบว่ารหัสผ่านตรงกันไหม
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("รหัสผ่านไม่ตรงกัน")),
      );
      return;
    }

    try {
      // 2. เรียกใช้ Firebase Auth เพื่อสร้างบัญชี
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 3. ถ้าสำเร็จ กลับไปหน้า Login
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("สร้างบัญชีสำเร็จ!")),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      // 4. จัดการข้อผิดพลาด (เช่น อีเมลซ้ำ, รหัสผ่านง่ายไป)
      String message = "เกิดข้อผิดพลาด";
      if (e.code == 'weak-password') message = "รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร";
      if (e.code == 'email-already-in-use') message = "อีเมลนี้ถูกใช้งานแล้ว";
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
        
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          // onPressed: () => Navigator.pop(context),
                          
                         onPressed: () {
                        // เปลี่ยนหน้าไปยัง PetStatusScreen และแทนที่หน้า Login ใน Stack
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                        ),
                      ),
                      const Text("สร้างบัญชีใหม่",
                          style: TextStyle(fontWeight: FontWeight.w500,fontSize: 16)),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: Form( // ครอบด้วย Form เพื่อการตรวจสอบข้อมูล
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 25),
                          const Text(
                    "ยินดีต้อนรับสู่ RegDog",
                    style: TextStyle(fontSize: 24, color: Colors.black, fontWeight: FontWeight.w500),
                  ),
                  const Text(
                    "เข้าสู่บัญชีของคุณ",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 15),
                         
                          _buildTextField(
                              controller: _emailController,
                              hint: "อีเมล",
                              icon: Icons.email_outlined),
                          const SizedBox(height: 10),
                          _buildTextField(
                              controller: _passwordController,
                              hint: "รหัสผ่าน",
                              icon: Icons.lock_outline,
                              isPassword: true),
                          const SizedBox(height: 10),
                          _buildTextField(
                              controller: _confirmPasswordController,
                              hint: "ยืนยันรหัสผ่าน",
                              icon: Icons.lock_outline,
                              isPassword: true),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 58,
                            child: ElevatedButton(
                              onPressed: _register, // เรียกใช้ฟังก์ชันที่แยกไว้ข้างบน
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFEF0B3),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30)),
                                elevation: 0,
                              ),
                              child: const Text("สร้างบัญชี",
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87)),
                            ),
                          ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      width: double.infinity,
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        // --- 1. ปรับขนาดตัวอักษรที่ผู้ใช้พิมพ์ ---
        style: const TextStyle(fontSize: 12), 
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: hint,
          // --- 2. ปรับขนาดตัวอักษร Hint (คำใบ้) ---
          hintStyle: const TextStyle(fontSize: 12), 
         prefixIcon: Padding(
  padding: const EdgeInsets.only(left: 12, right: 0), // left: ระยะห่างจากขอบกล่อง, right: ระยะห่างจากตัวหนังสือ
  child: Icon(icon, color: Colors.black26, size: 24),
), // ปรับขนาดไอคอนให้เล็กลงตามตัวหนังสือ
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.black12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFFFEF0B3), width: 2),
          ),
          // ปรับ Padding เล็กน้อยเพื่อให้ตัวหนังสืออยู่กลางกล่องพอดีเมื่อขนาดเล็กลง
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}