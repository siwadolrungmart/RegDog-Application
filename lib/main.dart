import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart'; // ← เพิ่มบรรทัดนี้
import 'package:regdogapp/screen/even_calendar.dart/playevent_screen.dart';
import 'package:regdogapp/screen/even_calendar.dart/selectevent_screen.dart';
import 'package:regdogapp/screen/even_calendar.dart/symptomevent_screen.dart';
import 'package:regdogapp/screen/even_calendar.dart/trainevent_screen.dart';
import 'package:regdogapp/screen/even_calendar.dart/vaccinevent_screen.dart';
import 'package:regdogapp/screen/even_calendar.dart/vetvisitevent_screen.dart';
import 'package:regdogapp/screen/even_calendar.dart/walkevent_screen.dart';

// Import หน้าจอต่างๆ
import 'package:regdogapp/screen/login_screen.dart';
import 'package:regdogapp/screen/create_account_screen.dart';
import 'package:regdogapp/screen/navbar_screen/calendar_screen.dart';
import 'package:regdogapp/screen/navbar_screen/dogprofile_screen.dart';
import 'package:regdogapp/screen/register_screen/registerhavedog.dart';
import 'package:regdogapp/screen/register_screen/registergender.dart';
import 'package:regdogapp/screen/register_screen/registerdogname.dart';
import 'package:regdogapp/screen/register_screen/registerbirthday.dart';
import 'package:regdogapp/screen/register_screen/registerbreed.dart';
import 'package:regdogapp/screen/dog_list.dart';
import 'package:regdogapp/screen/navbar_screen/home_screen.dart';

// Import Provider
import 'package:regdogapp/providers/current_dog_provider.dart'; // ← เพิ่มบรรทัดนี้

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CurrentDogProvider>(
          create: (_) => CurrentDogProvider(),
        ),
        // ถ้ามี Provider อื่น ๆ ในอนาคต (เช่น AuthProvider) ให้เพิ่มที่นี่
      ],
      child: const RegDogApp(),
    ),
  );
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
      home: const CalendarPage(),
    );
  }
}