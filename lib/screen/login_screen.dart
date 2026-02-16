import 'package:flutter/material.dart';
// ต้อง import ไฟล์หน้าสร้างบัญชีเพื่อให้เรียกใช้ class ได้
import 'package:regdogapp/screen/create_account_screen.dart'; 
// นำเข้าไฟล์หน้าเลือกสถานะสุนัข (ตรวจสอบ path ให้ตรงกับโปรเจกต์ของคุณ)
import 'package:regdogapp/screen/registerfirst.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            // ปรับ path ให้ตรงกับโฟลเดอร์ assets/images/
            image: AssetImage('assets/bg_watercolor.png'), 
            fit: BoxFit.cover,
          ),
          
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  
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
                              'assets/dog.png', // ปรับ path รูปสุนัข
                              height: 280,
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
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 35),

                  // --- 2. ส่วนหัวข้อ (Headers) ---
                  const Text(
                    "ยินดีต้อนรับสู่ RegDog",
                    style: TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                  const Text(
                    "เข้าสู่บัญชีของคุณ",
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 25),

                  // --- 3. ช่องกรอกข้อมูล ---
                  _buildTextField(
                    controller: _emailController,
                    hint: "อีเมล",
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _passwordController,
                    hint: "รหัสผ่าน",
                    icon: Icons.lock_outline,
                    isPassword: true,
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => print("Forgot Password"),
                      child: const Text("ลืมรหัสผ่าน?", style: TextStyle(color: Colors.black45)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // --- 4. ปุ่มเข้าสู่ระบบ (อัปเดตแล้ว) ---
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: () {
                        // เปลี่ยนหน้าไปยัง PetStatusScreen และแทนที่หน้า Login ใน Stack
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Registerfirst(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFEF0B3),
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text("เข้าสู่ระบบ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                    height: 58,
                    child: OutlinedButton.icon(
                      onPressed: () => print("Google Login"),
                      icon: Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                        height: 22,
                      ),
                      label: const Text("Google", style: TextStyle(color: Colors.black87, fontSize: 16)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.black12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // --- 7. Footer สร้างบัญชีใหม่ ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("คุณยังไม่มีบัญชีใช่ไหม?", style: TextStyle(color: Colors.black45)),
                      TextButton(
                        onPressed: () {
                          // ใช้ Navigator เพื่อเปลี่ยนหน้าไปยัง CreateAccountScreen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreateAccountScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "สร้างบัญชีใหม่", 
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
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
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.black26),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.black12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFFFEF0B3), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}