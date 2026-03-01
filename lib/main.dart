import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:regdogapp/screen/dog_list.dart';
import 'package:regdogapp/screen/homepage.dart';
import 'firebase_options.dart';
// Import ไฟล์หน้าจอต่างๆ ของคุณ
import 'package:regdogapp/screen/login_screen.dart'; 
import 'package:regdogapp/screen/create_account_screen.dart';
import 'package:regdogapp/screen/register/registerhavedog.dart'; 
import 'package:regdogapp/screen/register/registergender.dart'; 
import 'package:regdogapp/screen/register/registerdogname.dart'; 
import 'package:regdogapp/screen/register/registerbirthday.dart'; 
import 'package:regdogapp/screen/register/registerbreed.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ เปลี่ยนจาก Homepage เป็น RegDogApp
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
        scaffoldBackgroundColor: Colors.transparent,
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      builder: (context, child) {
        return Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/bg_watercolor.png'), 
              fit: BoxFit.cover,
            ),
          ),
          child: Padding(
            // ปรับ padding ตามความเหมาะสม
            padding: const EdgeInsets.only(top: 0, left: 16, right: 16), 
            child: child,
          ),
        );
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('th', 'TH'),
      ],
      
      // ✅ ตั้งหน้าแรกเป็น DogListPage เพื่อให้ผู้ใช้เลือกสุนัขก่อน
      home: const DogListPage(), 
    );
  }
}