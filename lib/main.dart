import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 
import 'package:regdogapp/screen/login_screen.dart'; 
import 'package:regdogapp/screen/registerhavedog.dart'; 
import 'package:regdogapp/screen/registergender.dart'; 
import 'package:google_fonts/google_fonts.dart';
import 'package:regdogapp/screen/registerdogname.dart'; 
import 'package:regdogapp/screen/registerbirthday.dart'; 
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:regdogapp/screen/registerbreed.dart'; 
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
        // ปรับแต่งสีหลักที่นี่ (คุณใช้ Colors.orange ไว้)
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        
        // --- 1. ตั้งค่าให้พื้นหลังโปร่งใส เพื่อให้มองทะลุเห็นรูปภาพได้ ---
        scaffoldBackgroundColor: Colors.transparent,
        
        // --- 2. เรียกใช้ Google Fonts ให้เป็น Inter ทั้งแอป ---
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      
      // --- 3. ตั้งค่ารูปพื้นหลังให้ครอบคลุมทุกหน้าจอ ---
      builder: (context, child) {
        return Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/bg_watercolor.png'), 
              fit: BoxFit.cover,
            ),
          ),
          child: child,
        );
      },

      // ให้ปฏิทินรู้จักภาษาไทย 
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('th', 'TH'), // ระบุว่าแอปรองรับภาษาไทย
      ],
      
      // หน้าแรกที่แอปจะเปิดขึ้นมา
      home: const Registerbreed(), 
    );
  }
}