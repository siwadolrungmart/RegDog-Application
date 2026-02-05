// 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
          // พื้นหลัง
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/bg_watercolor.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const Text("สร้างบัญชีใหม่",
                          style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Form( // ครอบด้วย Form เพื่อการตรวจสอบข้อมูล
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 40),
                          const Text("ยินดีต้อนรับสู่ RegDog",
                              style: TextStyle(fontSize: 18, color: Colors.black54)),
                          const Text("สร้างบัญชีของคุณ",
                              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 30),
                          _buildField(
                              controller: _emailController,
                              hint: "อีเมล",
                              icon: Icons.email_outlined),
                          const SizedBox(height: 16),
                          _buildField(
                              controller: _passwordController,
                              hint: "รหัสผ่าน",
                              icon: Icons.lock_outline,
                              isPass: true),
                          const SizedBox(height: 16),
                          _buildField(
                              controller: _confirmPasswordController,
                              hint: "ยืนยันรหัสผ่าน",
                              icon: Icons.lock_outline,
                              isPass: true),
                          const SizedBox(height: 30),
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
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
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

  Widget _buildField(
      {required TextEditingController controller,
      required String hint,
      required IconData icon,
      bool isPass = false}) {
    return TextFormField( // เปลี่ยนจาก TextField เป็น TextFormField
      controller: controller,
      obscureText: isPass,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.black26),
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.black12)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.black12)),
      ),
    );
  }
}