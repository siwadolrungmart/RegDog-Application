import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:regdogapp/screen/login_screen.dart';
import 'package:regdogapp/screen/navbar_screen/calendar_screen.dart';
import 'package:regdogapp/providers/current_dog_provider.dart';
import 'package:regdogapp/screen/navbar_screen/home_screen.dart';
import 'package:regdogapp/screen/navbar_screen/places_screen.dart';
import 'package:regdogapp/screen/qr_scan_result_page.dart';
import 'package:regdogapp/screen/register_screen/profile_user_screen.dart';
import 'package:regdogapp/service/notification_service.dart'; 
import 'firebase_options.dart';
@override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 🔴 ส่วนสำคัญ: เชื่อมต่อ Key เพื่อใช้เปลี่ยนหน้าจาก Notification
      navigatorKey: NotificationService.navigatorKey, 

      title: 'RegDog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent,
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      
      // ==========================================
      // 🟢 เพิ่มส่วนนี้: เพื่อดักจับลิงก์ /scan จากคิวอาร์โค้ด
      // ==========================================
      onGenerateRoute: (settings) {
        if (settings.name != null && settings.name!.startsWith('/scan')) {
          final uri = Uri.parse(settings.name!);
          final dogId = uri.queryParameters['dogId'];

          if (dogId != null && dogId.isNotEmpty) {
            return MaterialPageRoute(
              builder: (context) => QrScanResultPage(dogId: dogId),
            );
          }
        }
        return null; // ถ้าไม่ใช่ลิงก์ /scan ก็ปล่อยให้แอปทำงานปกติต่อไป
      },
      // ==========================================

      builder: (context, child) {
        return Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/bg_watercolor.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Padding(
            // ปรับ padding ให้เหมาะสม (ถ้า child เป็น null จะไม่ทำงาน)
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
      home: const Homepage(),
    );
  }