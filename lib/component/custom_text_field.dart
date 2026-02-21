import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isPassword;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.isPassword = false,
  });

  @override
  Widget build(BuildContext context) {
    // ใช้ Theme.of(context) เพื่อดึงค่าสีที่ตั้งไว้ใน main.dart มาใช้
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      // M3 แนะนำให้ใช้สไตล์ตัวอักษรจาก TextTheme
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
      textAlignVertical: TextAlignVertical.center,
      decoration: InputDecoration(
        isDense: true, // M3 property เพื่อลดพื้นที่ว่างที่ไม่จำเป็น
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: Colors.black26),
        prefixIcon: Icon(icon, size: 20),
        
        // การตั้งค่าสีพื้นหลังแบบ M3
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),

        // ขอบปกติ
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        
        // ขอบตอนกด (Focused) ใช้สี Primary จาก Theme
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),

        // กำหนดความสูงผ่าน contentPadding แทนการครอบด้วย Container
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}