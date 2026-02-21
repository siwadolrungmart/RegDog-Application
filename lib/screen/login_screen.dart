import 'package:flutter/material.dart';
// ต้อง import ไฟล์หน้าสร้างบัญชีเพื่อให้เรียกใช้ class ได้
import 'package:regdogapp/screen/create_account_screen.dart'; 
// นำเข้าไฟล์หน้าเลือกสถานะสุนัข (ตรวจสอบ path ให้ตรงกับโปรเจกต์ของคุณ)
import 'package:regdogapp/screen/register/registerhavedog.dart'; 

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
      
          
        // ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
               
                  
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
                              height: 300,
                              width: 398,
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
      padding: EdgeInsets.zero,        // ลบ Padding ภายในปุ่มออก
      minimumSize: Size.zero,         // ลบขนาดขั้นต่ำออก
      tapTargetSize: MaterialTapTargetSize.shrinkWrap, // บีบพื้นที่กดให้เท่ากับเนื้อหา
    ),
    child: const Text(
      "ลืมรหัสผ่าน?",
      style: TextStyle(
        fontSize: 12,
        color: Colors.black45,
        fontWeight: FontWeight.w500,
      ),
    ),
  ),
),
                  const SizedBox(height: 10),

                  // --- 4. ปุ่มเข้าสู่ระบบ (อัปเดตแล้ว) ---
                  SizedBox(
                    width: double.infinity,
                    height: 62,
                    child: ElevatedButton(
                      onPressed: () {
                        // เปลี่ยนหน้าไปยัง PetStatusScreen และแทนที่หน้า Login ใน Stack
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Registerhavedog(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFEF0B3),
                        foregroundColor: Colors.black87,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text("เข้าสู่ระบบ", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
                      onPressed: () => print("Google Login"),
                      icon: Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                        height: 22,
                      ),
                      label: const Text("Google", style: TextStyle(color: Colors.black87,fontWeight: FontWeight.w600, fontSize: 14)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.black12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),

                  // --- 7. Footer สร้างบัญชีใหม่ ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("คุณยังไม่มีบัญชีใช่ไหม?", style: TextStyle(color: Colors.black45, fontWeight: FontWeight.w500)),
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