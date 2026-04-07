import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // เพิ่ม Import สำหรับ Firestore
import 'package:flutter/material.dart';
import 'package:regdogapp/screen/login_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _nameController = TextEditingController(); // เพิ่ม Controller สำหรับชื่อผู้ใช้
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // ฟังก์ชันสมัครสมาชิก
  Future<void> _register() async {
    // 1. ตรวจสอบข้อมูลเบื้องต้น
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณากรอกชื่อผู้ใช้งาน")),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("รหัสผ่านไม่ตรงกัน")),
      );
      return;
    }

    try {
      // 2. เรียกใช้ Firebase Auth เพื่อสร้างบัญชี
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 3. ดึง UID ของ user ที่พึ่งสร้างเสร็จ
      String uid = userCredential.user!.uid;

      // 4. บันทึกข้อมูลลง Firestore ใน Collection 'users' ตามโครงสร้างที่ออกแบบไว้
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        "uid": uid,
        "email": _emailController.text.trim(),
        "displayName": _nameController.text.trim(),
        "profileImageUrl": "", // เว้นว่างไว้ก่อน ให้ไปอัปโหลดรูปในหน้า Profile ทีหลัง
        "fcmToken": "", // เว้นว่างไว้ก่อน จะอัปเดตเมื่อผู้ใช้ล็อกอินและขอสิทธิ์ Notification
        "createdAt": FieldValue.serverTimestamp(), // ใช้เวลาจาก Server ของ Firebase
        "updatedAt": FieldValue.serverTimestamp(),
      });

      // 5. ถ้าสำเร็จ กลับไปหน้า Login
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("สร้างบัญชีสำเร็จ!")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      // 6. จัดการข้อผิดพลาด
      String message = "เกิดข้อผิดพลาด: ${e.message}";
      if (e.code == 'weak-password') {
        message = "รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร";
      } else if (e.code == 'email-already-in-use') {
        message = "อีเมลนี้ถูกใช้งานแล้ว";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      // เผื่อกรณี Error จาก Firestore
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาดในการบันทึกข้อมูล: $e")),
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
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const Text(
                        "สร้างบัญชีใหม่",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20), // เพิ่ม padding เล็กน้อยให้ UI ดูมีขอบ
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 25),
                          const Text(
                            "ยินดีต้อนรับสู่ RegDog",
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Text(
                            "เข้าสู่บัญชีของคุณ",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 15),

                          // เพิ่ม TextField สำหรับชื่อผู้ใช้งาน
                          _buildTextField(
                            controller: _nameController,
                            hint: "ชื่อผู้ใช้งาน",
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 10),

                          _buildTextField(
                            controller: _emailController,
                            hint: "อีเมล",
                            icon: Icons.email_outlined,
                          ),
                          const SizedBox(height: 10),
                          _buildTextField(
                            controller: _passwordController,
                            hint: "รหัสผ่าน",
                            icon: Icons.lock_outline,
                            isPassword: true,
                          ),
                          const SizedBox(height: 10),
                          _buildTextField(
                            controller: _confirmPasswordController,
                            hint: "ยืนยันรหัสผ่าน",
                            icon: Icons.lock_outline,
                            isPassword: true,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 58,
                            child: ElevatedButton(
                              onPressed: _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFEF0B3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                "สร้างบัญชี",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
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
        style: const TextStyle(fontSize: 12),
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 0),
            child: Icon(icon, color: Colors.black26, size: 24),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.black12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFFFEF0B3), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }
}