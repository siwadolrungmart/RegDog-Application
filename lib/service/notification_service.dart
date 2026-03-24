import 'dart:io';
import 'package:flutter/material.dart'; // เพิ่มเพื่อใช้ Navigator และ MaterialPageRoute
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // เพิ่มเพื่อดึงข้อมูลเมื่อกดแจ้งเตือน

// Import ไฟล์หน้าและ Model ของคุณ
import '../component/event_settings.dart'; 
import '../screen/even_calendar.dart/walkevent_screen.dart'; // เปลี่ยน path ให้ตรงกับไฟล์ AddWalkEventPage ของคุณ

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  // สร้าง GlobalKey เพื่อใช้เปลี่ยนหน้าโดยไม่ต้องมี BuildContext
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const int _maxPreScheduleCount = 30; 

  // ==========================================
  // 1. Initializer (ปรับปรุงเพื่อให้รองรับการกด)
  // ==========================================
  static Future<void> init() async {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentSound: true,
      defaultPresentBadge: true,
    );

    const InitializationSettings initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onTapNotification, // 🟢 เพิ่มตัวดักจับการกด
    );
  }

  // 🟢 ฟังก์ชันเมื่อผู้ใช้กดที่การแจ้งเตือน
  static void _onTapNotification(NotificationResponse response) async {
    final String? eventId = response.payload;
    if (eventId == null || eventId.isEmpty) return;

    try {
      // ดึงข้อมูลกิจกรรมจาก Firestore ล่าสุด
      final doc = await FirebaseFirestore.instance.collection('dog_activities').doc(eventId).get();
      
      if (doc.exists && navigatorKey.currentState != null) {
        final data = doc.data() as Map<String, dynamic>;
        
        DateTime start = DateTime.now();
        if (data['start_time'] is Timestamp) start = (data['start_time'] as Timestamp).toDate();

        // 🟢 สั่ง Navigator ให้เปิดหน้ารายละเอียด
        navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (context) => AddWalkEventPage(
              selectedDateFromCalendar: start,
              eventId: eventId,
              eventData: data,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Notification Tap Error: $e");
    }
  }

  // ==========================================
  // 2. Schedule Event (ปรับปรุง Payload และ Body)
  // ==========================================
  static Future<void> scheduleEventNotification({
    required String eventId,
    required String title,
    required String body, // จริงๆ body นี้จะถูกเขียนทับด้วย _getFormattedBody
    required DateTime startDateTime,
    required int? reminderMinutes,
    required RecurrenceData recurrenceData,
    String? payload, // 🟢 รับ payload เพิ่ม
  }) async {
    await cancelEventNotifications(eventId);

    if (reminderMinutes == null) return;

    List<DateTime> scheduledDates = _calculateOccurrences(startDateTime, recurrenceData);

    // 🟢 สร้าง Body ตาม UI ที่กำหนด
    String formattedBody = _getFormattedBody(reminderMinutes, title);

    for (int i = 0; i < scheduledDates.length; i++) {
      DateTime eventTime = scheduledDates[i];
      DateTime notifyTime = eventTime.subtract(Duration(minutes: reminderMinutes));

      if (notifyTime.isBefore(DateTime.now())) continue;

      int notificationId = "${eventId}_$i".hashCode;

      await _notificationsPlugin.zonedSchedule(
        notificationId,
        "แจ้งเตือนกิจกรรมน้องหมา", // เปลี่ยน Title หลัก
        formattedBody, // 🟢 ใช้ Body ที่จัด Format แล้ว
        tz.TZDateTime.from(notifyTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'dog_calendar_events', 'Calendar Reminder',
            channelDescription: 'แจ้งเตือนกิจกรรมปฏิทินของสุนัข',
            importance: Importance.max, priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: eventId, // 🟢 ส่ง eventId ไปเป็น payload
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  // 🟢 Helper แปลงนาทีเป็นข้อความภาษาไทยตาม UI
  static String _getFormattedBody(int minutes, String eventName) {
    String timeLabel = "";
    if (minutes == 0) timeLabel = "เมื่อถึงเวลากิจกรรม";
    else if (minutes == 5) timeLabel = "5 นาที ก่อนหน้า";
    else if (minutes == 10) timeLabel = "10 นาที ก่อนหน้า";
    else if (minutes == 15) timeLabel = "15 นาที ก่อนหน้า";
    else if (minutes == 30) timeLabel = "30 นาที ก่อนหน้า";
    else if (minutes == 60) timeLabel = "1 ชั่วโมง ก่อนหน้า";
    else if (minutes == 1440) timeLabel = "1 วัน ก่อนหน้า";
    else timeLabel = "$minutes นาที ก่อนหน้า";

    return "แจ้งเตือน: $eventName ($timeLabel)";
  }

  // ... (ฟังก์ชัน cancelEventNotifications และ _calculateOccurrences คงเดิมตามที่คุณเขียนมาได้เลย) ...
  
  static Future<void> cancelEventNotifications(String eventId) async {
    for (int i = 0; i < _maxPreScheduleCount; i++) {
      await _notificationsPlugin.cancel("${eventId}_$i".hashCode);
    }
  }

  // (ส่วน _calculateOccurrences ของคุณถูกต้องดีแล้วครับ ไม่ต้องแก้ไข)
  static List<DateTime> _calculateOccurrences(DateTime start, RecurrenceData rec) {
    // ... ยกโค้ดเดิมของคุณมาใส่ตรงนี้ ...
    if (rec.repeatType == 'none') return [start];
    List<DateTime> occurrences = [];
    DateTime current = start;
    int generatedCount = 0;
    int limitBreaker = 0;
    DateTime startMonday = DateTime(start.year, start.month, start.day).subtract(Duration(days: start.weekday - 1));
    int originalDay = start.day;
    int stepMultiplier = 0; 

    while (occurrences.length < _maxPreScheduleCount) {
      limitBreaker++;
      if (limitBreaker > 2000) break; 
      if (rec.count != null && generatedCount >= rec.count!) break;

      if (rec.repeatType == 'daily') {
        int daysDiff = current.difference(start).inDays;
        if (daysDiff % rec.interval == 0) {
          occurrences.add(current);
          generatedCount++;
        }
        current = current.add(const Duration(days: 1));
      } 
      else if (rec.repeatType == 'weekly') {
        if (rec.weeklyDays.isEmpty || rec.weeklyDays.contains(current.weekday)) {
          DateTime currentMonday = DateTime(current.year, current.month, current.day).subtract(Duration(days: current.weekday - 1));
          int weeksDiff = currentMonday.difference(startMonday).inDays ~/ 7;
          if (weeksDiff % rec.interval == 0) {
            occurrences.add(current);
            generatedCount++;
          }
        }
        current = current.add(const Duration(days: 1));
      } 
      else if (rec.repeatType == 'monthly') {
        int targetMonth = start.month + (stepMultiplier * rec.interval);
        int targetYear = start.year + ((targetMonth - 1) ~/ 12);
        int actualMonth = ((targetMonth - 1) % 12) + 1;
        int daysInTargetMonth = DateTime(targetYear, actualMonth + 1, 0).day;
        int clampedDay = originalDay > daysInTargetMonth ? daysInTargetMonth : originalDay;
        current = DateTime(targetYear, actualMonth, clampedDay, start.hour, start.minute);
        if (rec.endDate != null && current.isAfter(rec.endDate!.add(const Duration(days: 1)))) break;
        occurrences.add(current);
        generatedCount++;
        stepMultiplier++; 
      } 
      else if (rec.repeatType == 'yearly') {
        int targetYear = start.year + (stepMultiplier * rec.interval);
        int actualMonth = start.month;
        int daysInTargetMonth = DateTime(targetYear, actualMonth + 1, 0).day;
        int clampedDay = originalDay > daysInTargetMonth ? daysInTargetMonth : originalDay;
        current = DateTime(targetYear, actualMonth, clampedDay, start.hour, start.minute);
        if (rec.endDate != null && current.isAfter(rec.endDate!.add(const Duration(days: 1)))) break;
        occurrences.add(current);
        generatedCount++;
        stepMultiplier++; 
      }
      if ((rec.repeatType == 'daily' || rec.repeatType == 'weekly') && 
          rec.endDate != null && current.isAfter(rec.endDate!.add(const Duration(days: 1)))) {
        break;
      }
    }
    return occurrences;
  }

  static Future<void> requestPermission() async {
    if (Platform.isIOS) {
      await _notificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (Platform.isAndroid) {
      await _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    }
  }
}