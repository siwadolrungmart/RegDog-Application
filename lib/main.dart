import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Import ไฟล์หน้าจอต่างๆ ของคุณ
import 'firebase_options.dart'; 
import 'package:regdogapp/screen/login_screen.dart'; 
import 'package:regdogapp/screen/create_account_screen.dart';
import 'package:regdogapp/screen/register/registerhavedog.dart'; 
import 'package:regdogapp/screen/register/registergender.dart'; 
import 'package:regdogapp/screen/register/registerdogname.dart'; 
import 'package:regdogapp/screen/register/registerbirthday.dart'; 
import 'package:regdogapp/screen/register/registerbreed.dart'; 

// --- 1. คลาสสำหรับเก็บชื่อสีที่จะใช้ในโปรเจ็กต์ ---
class AppColors {
  static const Color primary = Color(0xFFFEF0B3); // สีหลัก (เช่น สีขอบตอนกดเลือก)
  static const Color secondary = Color(0xFF6200EE);
  static const Color accent = Colors.orange;
  static const Color backgroundWhite = Colors.white;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      
      // --- 2. ตั้งค่า Theme ของแอป ---
      theme: ThemeData(
        useMaterial3: true,
        // กำหนด ColorScheme กลางของแอป
        // colorScheme: ColorScheme.fromSeed(
        //   seedColor: AppColors.primary,
        //   primary: AppColors.primary,
        //   secondary: AppColors.secondary,
        // ),
        
        // ตั้งค่าพื้นหลังของ Scaffold ให้โปร่งใสเพื่อโชว์รูปจาก Container builder
        scaffoldBackgroundColor: Colors.transparent,
        
        // เรียกใช้ Google Fonts (Inter) ทั้งแอป
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
      ),

      // --- 3. ตั้งค่า Background และระยะห่าง Dynamic Island (55 px) ---
      builder: (context, child) {
        return Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/bg_watercolor.png'), 
              fit: BoxFit.cover,
            ),
          ),
          child: Padding(
            // เว้นระยะด้านบน 55 px เพื่อหลบ Dynamic Island สำหรับ iPhone 15 Pro Max
            padding: const EdgeInsets.only(top: 55, left: 16, right: 16),
            child: child,
          ),
        );
      },

      // --- 4. ตั้งค่า Localization (ภาษาไทย) ---
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('th', 'TH'),
      ],
      
      home: const CreateAccountScreen(), 
    );
  }
}