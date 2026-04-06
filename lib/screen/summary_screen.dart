import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SummaryPage extends StatelessWidget {
  const SummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    
      appBar: AppBar(
        title: Text(
          "สรุป",
          style: GoogleFonts.mitr(
            color: const Color(0xFF6DA2B8), 
            fontWeight: FontWeight.w500,
          ),
        ),
      
        elevation: 0, // เอาเงาใต้ AppBar ออกให้ดูคลีนๆ
        iconTheme: const IconThemeData(color: Color(0xFF6DA2B8)), // สีปุ่มย้อนกลับ
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.bar_chart,
              size: 80,
              
            ),
            const SizedBox(height: 16),
            Text(
              "หน้าสรุป (กำลังพัฒนา)",
              style: GoogleFonts.mitr(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}