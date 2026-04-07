import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // 🟢 เพิ่มบรรทัดนี้ เพื่อให้รู้จักคำสั่ง kIsWeb
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
import 'package:timezone/data/latest_all.dart' as tz;
// ==========================================
// 🚀 1. ฟังก์ชัน main() 
// ==========================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
tz.initializeTimeZones();
  await NotificationService.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CurrentDogProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

// ==========================================
// 🎨 2. คลาสหลักของแอป
// ==========================================
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    
    // ==========================================
    // 🌐 โหมด WEB: สำหรับคนสแกน QR Code (จะโชว์แค่นี้)
    // ==========================================
    if (kIsWeb) {
      // ดึงรหัส dogId จากลิงก์เว็บที่สแกนมา
      final dogId = Uri.base.queryParameters['dogId'];

      return MaterialApp(
        title: 'RegDog Pet Info',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          textTheme: GoogleFonts.interTextTheme(
            Theme.of(context).textTheme,
          ),
        ),
        // ถ้าลิงก์มี dogId ให้เปิดหน้าโชว์ข้อมูล ถ้าไม่มีให้ขึ้นว่าไม่พบข้อมูล
        home: (dogId != null && dogId.isNotEmpty)
            ? QrScanResultPage(dogId: dogId)
            : Scaffold(
                backgroundColor: const Color(0xFFF6F8F9),
                body: Center(
                  child: Text(
                    'ไม่พบข้อมูลสุนัข หรือลิงก์ไม่ถูกต้อง',
                    style: GoogleFonts.mitr(fontSize: 18, color: Colors.grey),
                  ),
                ),
              ),
      );
    }

    // ==========================================
    // 📱 โหมด APP: สำหรับแอป iOS ตัวเต็มของเรา
    // ==========================================
    return MaterialApp(
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
      
      // ดักจับลิงก์ /scan เผื่อกรณีแสกนจากในแอปตัวเอง
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
        return null;
      },

      builder: (context, child) {
        return Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/bg_watercolor.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Padding(
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
      
      // เข้าแอปมาเจอหน้า Login
      home: const LoginScreen(), 
    );
  }
}