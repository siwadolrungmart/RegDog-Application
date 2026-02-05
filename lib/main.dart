import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 
import 'package:regdogapp/screen/login_screen.dart'; 

void main() async {
  // ต้องมีบรรทัดนี้เสมอเมื่อมีการใช้ async ในฟังก์ชัน main
  WidgetsFlutterBinding.ensureInitialized();

  // เริ่มต้น Firebase ด้วยการดึงค่าจากไฟล์ที่เราสร้างมา
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const RegDogApp());
}

class RegDogApp extends StatelessWidget {
  const RegDogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RegDog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // ปรับแต่งสีหลักที่นี่
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
      ),
      // หน้าแรกที่แอปจะเปิดขึ้นมา
      home: const LoginScreen(), 
    );
  }
}