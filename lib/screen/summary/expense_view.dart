import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:regdogapp/providers/current_dog_provider.dart';

class ExpenseView extends StatefulWidget {
  const ExpenseView({super.key});

  @override
  State<ExpenseView> createState() => _ExpenseViewState();
}

class _ExpenseViewState extends State<ExpenseView> {
  String _timeFilter = '1_week'; 

  final List<Color> _dayColors = [
    const Color(0xFFFA8B8B), const Color(0xFFFCE18D), const Color(0xFFF9A8D4),
    const Color(0xFFC6F68D), const Color(0xFFFDBA8C), const Color(0xFFAEDBFA),
    const Color(0xFFE1C6FA),
  ];
  final Color _monthColor = const Color(0xFFAEDBFA); 
  final Color _weekColor = const Color(0xFFC6F68D); 

  DateTime _getStartDate() {
    final now = DateTime.now();
    switch (_timeFilter) {
      case '1_week': return now.subtract(const Duration(days: 7));
      case '6_weeks': return now.subtract(const Duration(days: 42));
      case '6_months': return DateTime(now.year, now.month - 6, now.day);
      default: return now.subtract(const Duration(days: 7));
    }
  }

  DateTime? _parseDateTime(dynamic field) {
    if (field == null) return null;
    if (field is Timestamp) return field.toDate();
    if (field is String) return DateTime.tryParse(field);
    return null;
  }

  double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final currentDogId = Provider.of<CurrentDogProvider>(context).currentDogId;

    if (currentDogId == null || currentDogId.isEmpty) {
      return const Center(child: Text("กรุณาเลือกสุนัขก่อน"));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('dog_activities')
          .where('dog_id', isEqualTo: currentDogId)
          .where('type', isEqualTo: 'expense')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("เกิดข้อผิดพลาด", style: GoogleFonts.mitr(color: Colors.red)));
        }

        final startDate = _getStartDate();
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        double totalExpense = 0;
        List<QueryDocumentSnapshot> filteredDocs = [];
        Map<int, double> groupedData = {};

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final date = _parseDateTime(data['start_time']);

            if (date != null && date.isAfter(startDate)) {
              filteredDocs.add(doc);
              double cost = _parseDouble(data['cost']);
              totalExpense += cost;

              if (_timeFilter == '6_months') {
                groupedData[date.month] = (groupedData[date.month] ?? 0) + cost;
              } else if (_timeFilter == '6_weeks') {
                final itemDate = DateTime(date.year, date.month, date.day);
                int daysDiff = today.difference(itemDate).inDays;
                int weeksAgo = daysDiff ~/ 7;
                if (weeksAgo >= 0 && weeksAgo < 6) {
                  groupedData[weeksAgo] = (groupedData[weeksAgo] ?? 0) + cost;
                }
              } else {
                int dayIndex = date.weekday == 7 ? 0 : date.weekday; 
                groupedData[dayIndex] = (groupedData[dayIndex] ?? 0) + cost;
              }
            }
          }
        }

        filteredDocs.sort((a, b) {
          final dateA = _parseDateTime((a.data() as Map<String, dynamic>)['start_time']) ?? DateTime.now();
          final dateB = _parseDateTime((b.data() as Map<String, dynamic>)['start_time']) ?? DateTime.now();
          return dateB.compareTo(dateA); 
        });

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTimeFilterDropdown(),
              const SizedBox(height: 16),
              _buildSummaryCard(totalExpense),
              const SizedBox(height: 30),
              _buildExpenseChart(groupedData),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text("ประวัติการบันทึก", style: GoogleFonts.mitr(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
              ),
              const SizedBox(height: 16),
              if (filteredDocs.isNotEmpty)
                _buildExpenseHistoryList(filteredDocs)
              else
                _buildEmptyState("ไม่มีข้อมูลประวัติค่าใช้จ่าย"),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeFilterDropdown() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFFFDEBB3), borderRadius: BorderRadius.circular(20)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _timeFilter,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6DA2B8)),
          style: GoogleFonts.mitr(color: const Color(0xFF6DA2B8), fontSize: 16),
          dropdownColor: const Color(0xFFFDEBB3),
          items: const [
            DropdownMenuItem(value: '1_week', child: Center(child: Text("1 สัปดาห์ย้อนหลัง"))),
            DropdownMenuItem(value: '6_weeks', child: Center(child: Text("6 สัปดาห์ย้อนหลัง"))),
            DropdownMenuItem(value: '6_months', child: Center(child: Text("6 เดือนย้อนหลัง"))),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _timeFilter = value);
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(double totalExpense) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(color: const Color(0xFFE2F3F5), borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Text("${NumberFormat('#,##0').format(totalExpense)} ฿", style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.black87)),
          Text("ค่าใช้จ่ายทั้งหมด", style: GoogleFonts.mitr(fontSize: 16, color: const Color(0xFF6DA2B8))),
        ],
      ),
    );
  }

  Widget _buildExpenseChart(Map<int, double> data) {
    double maxY = 1000;
    if (data.isNotEmpty) {
      double maxVal = data.values.reduce(max);
      maxY = maxVal > 0 ? maxVal * 1.3 : 1000;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1C6FA), width: 1.5),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          minY: 0,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true, reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  String label = '';
                  if (_timeFilter == '6_months') {
                    final targetDate = DateTime(DateTime.now().year, DateTime.now().month - (5 - value.toInt()), 1);
                    label = "${targetDate.month}/${targetDate.year}";
                  } else if (_timeFilter == '6_weeks') {
                    int weeksAgo = 5 - value.toInt();
                    label = weeksAgo == 0 ? "วีคนี้" : "$weeksAgo วีคก่อน";
                  } else {
                    const days = ['อา', 'จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส']; 
                    int index = value.toInt();
                    if (index >= 0 && index < 7) label = days[index];
                  }
                  return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(label, style: GoogleFonts.mitr(fontSize: 10, color: Colors.grey.shade500)));
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  double total = 0;
                  Color textColor = Colors.black;

                  if (_timeFilter == '6_months') {
                    int keyIndex = DateTime(DateTime.now().year, DateTime.now().month - (5 - value.toInt()), 1).month;
                    total = data[keyIndex] ?? 0;
                    textColor = _monthColor;
                  } else if (_timeFilter == '6_weeks') {
                    int weeksAgo = 5 - value.toInt();
                    total = data[weeksAgo] ?? 0;
                    textColor = _weekColor;
                  } else {
                    total = data[value.toInt()] ?? 0;
                    textColor = _dayColors[value.toInt() % 7];
                  }

                  if (total <= 0) return const SizedBox.shrink();
                  String displayValue = total < 1000 ? "${total.toStringAsFixed(0)}฿" : "${(total / 1000).toStringAsFixed(1)}k"; 
                  return Padding(padding: const EdgeInsets.only(bottom: 4.0), child: Text(displayValue, style: GoogleFonts.mitr(fontSize: 10, color: textColor)));
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true, drawVerticalLine: false,
            horizontalInterval: maxY / 4 > 0 ? maxY / 4 : 1,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade100, strokeWidth: 1, dashArray: [5, 5]),
          ),
          borderData: FlBorderData(show: false),
          barGroups: _buildChartBars(data, maxY),
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildChartBars(Map<int, double> data, double maxY) {
    List<BarChartGroupData> bars = [];
    final now = DateTime.now();

    if (_timeFilter == '6_months') {
      for (int i = 0; i < 6; i++) {
        int month = DateTime(now.year, now.month - (5 - i), 1).month;
        bars.add(_makeBarData(i, data[month] ?? 0, _monthColor, maxY));
      }
    } else if (_timeFilter == '6_weeks') {
      for (int i = 0; i < 6; i++) {
        int weeksAgo = 5 - i; 
        bars.add(_makeBarData(i, data[weeksAgo] ?? 0, _weekColor, maxY));
      }
    } else {
      for (int i = 0; i < 7; i++) {
        bars.add(_makeBarData(i, data[i] ?? 0, _dayColors[i], maxY));
      }
    }
    return bars;
  }

  BarChartGroupData _makeBarData(int x, double y, Color color, double maxY) {
    double barHeight = y > 0 ? y : (maxY * 0.01); 
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: barHeight, color: color, width: 25,
          borderRadius: BorderRadius.circular(5),
          backDrawRodData: BackgroundBarChartRodData(show: false),
        ),
      ],
    );
  }

  Widget _buildExpenseHistoryList(List<QueryDocumentSnapshot> docs) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        final date = _parseDateTime(data['start_time']) ?? DateTime.now();
        String name = data['name'] ?? 'ไม่มีชื่อรายการ';
        double cost = _parseDouble(data['cost']);
        String formattedDate = DateFormat('dd/MM/yyyy HH:mm น.').format(date);

        return _buildHistoryCard(
          icon: Icons.payments_outlined,
          iconColor: Color(0xFF6DA2B8),
          bgColor: Color(0xFFCDE5F7),
          title: name,
          subtitle: formattedDate,
          trailingText: "-${NumberFormat('#,##0').format(cost)}฿",
          trailingColor: const Color(0xFFFA8B8B),
        );
      },
    );
  }

  Widget _buildHistoryCard({
    required IconData icon, required Color iconColor, required Color bgColor,
    required String title, required String subtitle, required String trailingText, required Color trailingColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle), child: Icon(icon, color: iconColor)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.mitr(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(subtitle, style: GoogleFonts.mitr(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(trailingText, textAlign: TextAlign.right, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: trailingColor)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Text(text, style: GoogleFonts.mitr(color: Colors.grey))));
  }
}