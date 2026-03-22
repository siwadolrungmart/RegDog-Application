import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:regdogapp/screen/login_screen.dart';
import 'package:regdogapp/screen/navbar_screen/calendar_screen.dart';
import 'package:regdogapp/providers/current_dog_provider.dart';
import 'package:regdogapp/screen/navbar_screen/places_screen.dart';
import 'package:regdogapp/service/notification_service.dart'; 
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CurrentDogProvider>(
          create: (_) => CurrentDogProvider(),
        ),
      ],
      child: const RegDogApp(),
    ),
  );
}

class RegDogApp extends StatefulWidget {
  const RegDogApp({super.key});

  @override
  State<RegDogApp> createState() => _RegDogAppState();
}

class _RegDogAppState extends State<RegDogApp> {
  
  @override
  void initState() {
    super.initState();
    // 🟢 ขอ Permission แจ้งเตือนเมื่อเปิดแอป
    NotificationService.requestPermission();
  }

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
      home: const  PlacePage(),
    );
  }
}