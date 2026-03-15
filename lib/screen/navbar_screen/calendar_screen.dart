import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import 'package:regdogapp/component/upperbar.dart';
import 'package:regdogapp/component/bar.dart';
import 'package:regdogapp/screen/dog_list.dart';
import 'package:regdogapp/screen/even_calendar.dart/selectevent_screen.dart';
import 'package:regdogapp/providers/current_dog_provider.dart';

import 'package:regdogapp/screen/even_calendar.dart/walkevent_screen.dart';
import 'package:regdogapp/screen/even_calendar.dart/playevent_screen.dart';
import 'package:regdogapp/screen/even_calendar.dart/trainevent_screen.dart';
import 'package:regdogapp/screen/even_calendar.dart/symptomevent_screen.dart';
import 'package:regdogapp/screen/even_calendar.dart/vaccinevent_screen.dart';
import 'package:regdogapp/screen/even_calendar.dart/medicineevent_screen.dart';
import 'package:regdogapp/screen/even_calendar.dart/vetvisitevent_screen.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  int _currentIndex = 1;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<QueryDocumentSnapshot> _allActivities = [];
  StreamSubscription<QuerySnapshot>? _activitySubscription;
  String? _currentDogId;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newDogId = Provider.of<CurrentDogProvider>(context).currentDogId;

    if (newDogId != _currentDogId) {
      _currentDogId = newDogId;
      _listenToActivities(_currentDogId);
    }
  }

  @override
  void dispose() {
    _activitySubscription?.cancel();
    super.dispose();
  }

  void _listenToActivities(String? dogId) {
    _activitySubscription?.cancel();

    if (dogId == null || dogId.isEmpty) {
      if (mounted) setState(() => _allActivities = []);
      return;
    }

    _activitySubscription = FirebaseFirestore.instance
        .collection('dog_activities')
        .where('dog_id', isEqualTo: dogId)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _allActivities = snapshot.docs;
        });
      }
    });
  }

  DateTime? _parseDateTime(dynamic field) {
    if (field == null) return null;
    if (field is Timestamp) return field.toDate();
    if (field is String) return DateTime.tryParse(field);
    return null;
  }

  bool _isEventOnDay(Map<String, dynamic> data, DateTime targetDay) {
    DateTime? start = _parseDateTime(data['start_time']);
    if (start == null) return false;

    DateTime sDate = DateTime(start.year, start.month, start.day);
    DateTime tDate = DateTime(targetDay.year, targetDay.month, targetDay.day);

    if (tDate.isBefore(sDate)) return false;

    var rec = data['recurrence'];
    if (rec == null || rec['type'] == 'none') {
      return sDate.isAtSameMomentAs(tDate);
    }

    if (rec['end_date'] != null) {
      DateTime? eDate = _parseDateTime(rec['end_date']);
      if (eDate != null) {
        DateTime normalizedEnd = DateTime(eDate.year, eDate.month, eDate.day);
        if (tDate.isAfter(normalizedEnd)) return false;
      }
    }

    String type = rec['type'];
    int interval = rec['interval'] ?? 1;

    if (type == 'daily') {
      int diffDays = tDate.difference(sDate).inDays;
      return diffDays % interval == 0;
    } else if (type == 'weekly') {
      List<dynamic> daysOfWeek = rec['days_of_week'] ?? [];
      if (!daysOfWeek.contains(tDate.weekday)) return false;

      int diffDays = tDate.difference(sDate).inDays;
      int diffWeeks = diffDays ~/ 7;
      return diffWeeks % interval == 0;
    } else if (type == 'monthly') {
      if (tDate.day != sDate.day) return false;
      int diffMonths = (tDate.year - sDate.year) * 12 + tDate.month - sDate.month;
      return diffMonths % interval == 0;
    } else if (type == 'yearly') {
      if (tDate.day != sDate.day || tDate.month != sDate.month) return false;
      int diffYears = tDate.year - sDate.year;
      return diffYears % interval == 0;
    }

    return false;
  }

  List<QueryDocumentSnapshot> _getEventsForDay(DateTime day) {
    return _allActivities.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return _isEventOnDay(data, day);
    }).toList();
  }

  String _getThaiDate(DateTime date) {
    const months = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
      'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];
    return 'วันที่ ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _getRecurrenceDateRange(Map<String, dynamic> data, DateTime start) {
    var rec = data['recurrence'];
    if (rec == null || rec['type'] == 'none') return '';

    String startStr = '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}/${start.year}';
    String endStr = "ไม่มีที่สิ้นสุด";

    if (rec['end_date'] != null) {
      DateTime? eDate = _parseDateTime(rec['end_date']);
      if (eDate != null) {
        endStr = '${eDate.day.toString().padLeft(2, '0')}/${eDate.month.toString().padLeft(2, '0')}/${eDate.year}';
      }
    }

    return ' , $startStr - $endStr';
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'walk': return Icons.pets;
      case 'play': return Icons.sports_volleyball;
      case 'train': return Icons.assignment;
      case 'symptom': return Icons.note_alt_outlined;
      case 'health': return Icons.domain;
      case 'vaccine': return Icons.vaccines;
      case 'medicine': return Icons.medication;
      case 'expense': return Icons.payments;
      default: return Icons.event;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents = _selectedDay != null ? _getEventsForDay(_selectedDay!) : [];

    return Scaffold(
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _currentIndex,
        onItemTapped: (index) => setState(() => _currentIndex = index),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HomeTopBar(
                showProfile: true,
                onMenuTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DogListPage())),
              ),

              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 690),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.all(Radius.circular(15)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, -1)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TableCalendar<QueryDocumentSnapshot>(
                      locale: 'th_TH',
                      firstDay: DateTime.utc(2000, 1, 1),
                      lastDay: DateTime.utc(2100, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      onHeaderTapped: (focusedDay) {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Center(child: Text("เลือกปี", style: GoogleFonts.inter(fontWeight: FontWeight.bold))),
                              content: SizedBox(
                                width: 300, height: 300,
                                child: Theme(
                                  data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF90C2D8))),
                                  child: YearPicker(
                                    firstDate: DateTime(2000), lastDate: DateTime(2100), selectedDate: _focusedDay,
                                    onChanged: (DateTime pickedYear) {
                                      setState(() {
                                        _focusedDay = DateTime(pickedYear.year, _focusedDay.month, _focusedDay.day);
                                        _selectedDay = _focusedDay;
                                      });
                                      Navigator.pop(context);
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      eventLoader: _getEventsForDay,
                      daysOfWeekStyle: const DaysOfWeekStyle(
                        weekendStyle: TextStyle(color: Colors.black87),
                        weekdayStyle: TextStyle(color: Colors.black87),
                      ),
                      calendarStyle: const CalendarStyle(
                        outsideDaysVisible: false,
                        weekendTextStyle: TextStyle(color: Colors.black87),
                        defaultTextStyle: TextStyle(color: Colors.black87),
                        todayDecoration: BoxDecoration(color: Color(0xFFFFC1CC), shape: BoxShape.circle),
                        selectedDecoration: BoxDecoration(color: Color(0xFF90C2D8), shape: BoxShape.circle),
                        markerSize: 0,
                      ),
                      headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, date, events) {
                          if (events.isEmpty) return const SizedBox();

                          // 🟢 Logic แยกหมวดหมู่ไอคอน
                          bool hasActivity = false; // เดิน, เล่น, ฝึก
                          bool hasHealth = false;   // อาการ, วัคซีน, ยา, พบสัตว์แพทย์
                          bool hasExpense = false;  // ค่าใช้จ่าย

                          for (var event in events) {
                            final data = event.data() as Map<String, dynamic>;
                            final type = data['type'] ?? '';

                            if (['walk', 'play', 'train'].contains(type)) {
                              hasActivity = true;
                            } else if (['symptom', 'health', 'vaccine', 'medicine'].contains(type)) {
                              hasHealth = true;
                            } else if (type == 'expense') {
                              hasExpense = true;
                            }
                          }

                          List<Widget> iconsToShow = [];
                          if (hasActivity) {
                            iconsToShow.add(const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 1.0),
                              child: Icon(Icons.bolt, size: 14, color: Color(0xFF6A97A8)),
                            ));
                          }
                          if (hasHealth) {
                            iconsToShow.add(const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 1.0),
                              child: Icon(Icons.health_and_safety, size: 14, color: Color(0xFF6A97A8)),
                            ));
                          }
                          if (hasExpense) {
                            iconsToShow.add(const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 1.0),
                              child: Icon(Icons.payments, size: 14, color: Color(0xFF6A97A8)),
                            ));
                          }

                          return Positioned(
                            bottom: 1,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: iconsToShow,
                            ),
                          );
                        },
                      ),
                    ),

                    const Divider(height: 30, thickness: 1, color: Color(0xFFEEEEEE)),
                    
                    Text(
                      _selectedDay != null ? _getThaiDate(_selectedDay!) : '',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),

                    if (selectedEvents.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: Text("ไม่มีกิจกรรมในวันนี้", style: GoogleFonts.inter(color: Colors.grey))),
                      )
                    else
                      ...selectedEvents.map((eventDoc) {
                        final data = eventDoc.data() as Map<String, dynamic>;
                        final startTime = _parseDateTime(data['start_time']) ?? DateTime.now(); 
                        final isReminderSet = data['reminder_offset_minutes'] != null;
                        
                        final recurrenceStr = _getRecurrenceDateRange(data, startTime);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: EventCard(
                            icon: _getIconForType(data['type']),
                            title: data['name'] ?? 'ไม่มีชื่อ',
                            time: DateFormat('HH:mm น.').format(startTime), 
                            recurrenceText: recurrenceStr.isNotEmpty ? recurrenceStr : null, 
                            hasBell: isReminderSet,
                            onTap: () {
                              final targetDate = _selectedDay ?? DateTime.now();
                              final dateToPass = DateTime(
                                targetDate.year,
                                targetDate.month,
                                targetDate.day,
                                startTime.hour,
                                startTime.minute,
                              );

                              if (data['type'] == 'play') {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => AddPlayEventPage(selectedDateFromCalendar: dateToPass, eventId: eventDoc.id, eventData: data)));
                              } else if (data['type'] == 'train') { 
                                Navigator.push(context, MaterialPageRoute(builder: (context) => AddTrainEventPage(selectedDateFromCalendar: dateToPass, eventId: eventDoc.id, eventData: data)));
                              } else if (data['type'] == 'symptom') { 
                                Navigator.push(context, MaterialPageRoute(builder: (context) => AddSymptomEventPage(selectedDateFromCalendar: dateToPass, eventId: eventDoc.id, eventData: data)));
                              } else if (data['type'] == 'vaccine') { 
                                Navigator.push(context, MaterialPageRoute(builder: (context) => AddVaccineEventPage(selectedDateFromCalendar: dateToPass, eventId: eventDoc.id, eventData: data)));
                              } else if (data['type'] == 'walk') {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => AddWalkEventPage(selectedDateFromCalendar: dateToPass, eventId: eventDoc.id, eventData: data)));
                              } else if (data['type'] == 'medicine') {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => AddMedicineEventPage(selectedDateFromCalendar: dateToPass, eventId: eventDoc.id, eventData: data)));
                              } else if (data['type'] == 'health') {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => AddVetVisitEventPage(selectedDateFromCalendar: dateToPass, eventId: eventDoc.id, eventData: data)));
                              }
                            },
                          ),
                        );
                      }).toList(),

                    Align(
                      alignment: Alignment.centerRight,
                      child: Material(
                        color: const Color(0xFFFEF0B3),
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => EventCategoryPage(selectedDate: _selectedDay ?? DateTime.now())));
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(width: 44, height: 44, alignment: Alignment.center, child: const Icon(Icons.add, color: Colors.black87, size: 26)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 100), 
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String time;
  final String? recurrenceText; 
  final bool hasBell;
  final VoidCallback? onTap;

  const EventCard({
    super.key,
    required this.icon,
    required this.title,
    required this.time,
    this.recurrenceText,
    this.hasBell = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F4FF).withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFADD8FF), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFADD8FF),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.blue[800], size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  RichText(
                    text: TextSpan(
                      text: time, 
                      style: GoogleFonts.mitr(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                      children: [
                        if (recurrenceText != null)
                          TextSpan(
                            text: recurrenceText, 
                            style: GoogleFonts.mitr(
                              fontSize: 12,
                              color: Colors.blue[600], 
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (hasBell)
              const Icon(
                Icons.notifications_active,
                color: Colors.orange,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}