import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // เพิ่ม Import
import 'package:google_sign_in/google_sign_in.dart'; // เพิ่ม Import
import 'package:cloud_firestore/cloud_firestore.dart'; // เพิ่ม Import

// ต้อง import ไฟล์หน้าสร้างบัญชีเพื่อให้เรียกใช้ class ได้
import 'package:regdogapp/screen/create_account_screen.dart';
// นำเข้าไฟล์หน้าเลือกสถานะสุนัข (ตรวจสอบ path ให้ตรงกับโปรเจกต์ของคุณ)
import 'package:regdogapp/screen/register_screen/registerhavedog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false; // เพิ่มสถานะการโหลด

  // -----------------------------------------------------
  // 1. ฟังก์ชันเข้าสู่ระบบด้วย อีเมล และ รหัสผ่าน
  // -----------------------------------------------------
  Future<void> _signInWithEmail() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณากรอกอีเมลและรหัสผ่าน")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // ถ้าสำเร็จ ไปหน้าถัดไป
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Registerhavedog()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = "เกิดข้อผิดพลาด";
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = "อีเมลหรือรหัสผ่านไม่ถูกต้อง";
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // -----------------------------------------------------
  // 2. ฟังก์ชันเข้าสู่ระบบด้วย Google (สำหรับ v7.0.0+)
  // -----------------------------------------------------
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      // 1. ดึง instance แบบใหม่ และทำการ initialize ก่อนใช้งานเสมอ
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize();

      // 2. ใช้คำสั่ง authenticate() แทนคำสั่ง signIn() เดิม
      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();
      
      // ถ้าผู้ใช้กดยกเลิกการล็อกอิน
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return; 
      }

      // 3. ดึงข้อมูล Auth (ในเวอร์ชันใหม่ไม่ต้องใช้คำว่า await ตรงนี้แล้ว)
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // 4. สร้าง Credential สำหรับ Firebase (เวอร์ชันใหม่ใช้แค่ idToken)
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // 5. เข้าสู่ระบบ Firebase ด้วย Credential ที่ได้
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // ตรวจสอบว่าผู้ใช้นี้เคยมีข้อมูลใน Firestore (users collection) หรือยัง
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        if (!userDoc.exists) {
          // ถ้าเป็นผู้ใช้ใหม่ (ล็อกอิน Google ครั้งแรก) ให้บันทึกข้อมูลตั้งต้นลงฐานข้อมูล
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            "uid": user.uid,
            "email": user.email ?? "",
            "displayName": user.displayName ?? "ผู้ใช้ Google",
            "profileImageUrl": user.photoURL ?? "",
            "fcmToken": "",
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
          });
        }

        // พาไปหน้าถัดไปเมื่อสำเร็จ
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Registerhavedog()),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เข้าสู่ระบบด้วย Google ไม่สำเร็จ: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0), // จัด Padding ให้อ่านง่าย
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // --- 1. ส่วนรูปสุนัข (Image Card) ---
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Image.asset(
                              'assets/dog.png',
                              height: 300,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(radius: 4, backgroundColor: Colors.black87),
                                  SizedBox(width: 6),
                                  CircleAvatar(radius: 4, backgroundColor: Colors.black26),
                                  SizedBox(width: 6),
                                  CircleAvatar(radius: 4, backgroundColor: Colors.black26),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- 2. ส่วนหัวข้อ (Headers) ---
                  const Text(
                    "ยินดีต้อนรับสู่ RegDog",
                    style: TextStyle(fontSize: 24, color: Colors.black, fontWeight: FontWeight.w500),
                  ),
                  const Text(
                    "เข้าสู่บัญชีของคุณ",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 15),

                  // --- 3. ช่องกรอกข้อมูล ---
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
                  const SizedBox(height: 5),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => print("Forgot Password"),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        "ลืมรหัสผ่าน?",
                        style: TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // --- 4. ปุ่มเข้าสู่ระบบด้วยอีเมล ---
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signInWithEmail, // เรียกใช้งาน
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFEF0B3),
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isLoading 
                          ? const SizedBox(
                              width: 24, 
                              height: 24, 
                              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                            ) 
                          : const Text(
                              "เข้าสู่ระบบ",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),

                  // --- 5. ตัวคั่น OR ---
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      children: [
                        Expanded(child: Divider(color: Colors.black12)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text("or", style: TextStyle(color: Colors.black38)),
                        ),
                        Expanded(child: Divider(color: Colors.black12)),
                      ],
                    ),
                  ),

                  // --- 6. ปุ่ม Google Login ---
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _signInWithGoogle, // เรียกใช้งาน Google Login
                      icon: Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                        height: 22,
                      ),
                      label: const Text(
                        "Google",
                        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.black12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // --- 7. Footer สร้างบัญชีใหม่ ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "คุณยังไม่มีบัญชีใช่ไหม? ",
                        style: TextStyle(color: Colors.black45, fontWeight: FontWeight.w500),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CreateAccountScreen()),
                          );
                        },
                        child: const Text(
                          "สร้างบัญชีใหม่",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
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
        style: const TextStyle(fontSize: 14),
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 14, color: Colors.black38),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 0),
            child: Icon(icon, color: Colors.black26, size: 22),
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