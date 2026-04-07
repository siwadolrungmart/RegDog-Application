import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:regdogapp/providers/current_dog_provider.dart';

class WalkView extends StatefulWidget {
  const WalkView({super.key});

  @override
  State<WalkView> createState() => _WalkViewState();
}

class _WalkViewState extends State<WalkView> {
  String _timeFilter = '1_week';

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

  int _parseInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _formatDuration(int totalMinutes) {
    if (totalMinutes == 0) return "0 นาที";
    int hours = totalMinutes ~/ 60;
    int mins = totalMinutes % 60;
    if (hours > 0) return "$hours:${mins.toString().padLeft(2, '0')} ชั่วโมง";
    return "$mins นาที";
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
          .where('type', isEqualTo: 'walk')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("เกิดข้อผิดพลาด", style: GoogleFonts.mitr(color: Colors.red)));
        }

        final startDate = _getStartDate();
        // 🟢 กำหนดเวลาสิ้นสุดคือปัจจุบัน เพื่อไม่ให้นำกิจกรรมในอนาคตมาแสดงในกราฟย้อนหลัง
        final endDate = DateTime.now(); 
        
        double totalDistance = 0;
        int totalDurationMins = 0;
        List<QueryDocumentSnapshot> filteredDocs = [];

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final date = _parseDateTime(data['start_time']);

            // 🟢 เพิ่มเงื่อนไขเช็คว่าต้องไม่เกินวัน/เวลาปัจจุบัน (!date.isAfter(endDate))
            if (date != null && date.isAfter(startDate) && !date.isAfter(endDate)) {
              filteredDocs.add(doc);
              
              double distance = _parseDouble(data['distance_km']); 
              int duration = _parseInt(data['duration_minutes']);

              totalDistance += distance;
              totalDurationMins += duration;
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
              _buildSummaryCard(totalDistance, totalDurationMins),
              const SizedBox(height: 30),
              _buildWalkChart(filteredDocs), 
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text("ประวัติการเดิน", style: GoogleFonts.mitr(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
              ),
              const SizedBox(height: 16),
              if (filteredDocs.isNotEmpty)
                _buildWalkHistoryList(filteredDocs)
              else
                _buildEmptyState("ไม่มีข้อมูลประวัติการเดิน"),
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

  Widget _buildSummaryCard(double totalDistance, int totalDurationMins) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(color: const Color(0xFFE2F3F5), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(NumberFormat('#,##0.00').format(totalDistance), style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(width: 4),
                  Text("กม.", style: GoogleFonts.mitr(fontSize: 16, color: Colors.black54)),
                ],
              ),
              Text("ระยะทางรวม", style: GoogleFonts.mitr(fontSize: 14, color: const Color(0xFF6DA2B8))),
            ],
          ),
          Container(width: 1, height: 50, color: Colors.grey.shade300),
          Column(
            children: [
              Text(_formatDuration(totalDurationMins), style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 4),
              Text("ระยะเวลารวม", style: GoogleFonts.mitr(fontSize: 14, color: const Color(0xFF6DA2B8))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWalkChart(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) {
      return Container(
        height: 240,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE1C6FA), width: 1.5),
        ),
        child: Center(child: Text("ไม่มีข้อมูลสำหรับแสดงกราฟ", style: GoogleFonts.mitr(color: Colors.grey))),
      );
    }

    List<QueryDocumentSnapshot> chartDocs = List.from(docs);
    chartDocs.sort((a, b) {
      final dateA = _parseDateTime((a.data() as Map<String, dynamic>)['start_time']) ?? DateTime.now();
      final dateB = _parseDateTime((b.data() as Map<String, dynamic>)['start_time']) ?? DateTime.now();
      return dateA.compareTo(dateB); 
    });

    List<FlSpot> spots = [];
    double maxDistance = 0;

    for (int i = 0; i < chartDocs.length; i++) {
      final data = chartDocs[i].data() as Map<String, dynamic>;
      double distance = _parseDouble(data['distance_km']);
      spots.add(FlSpot(i.toDouble(), distance));
      if (distance > maxDistance) {
        maxDistance = distance;
      }
    }

    // 🟢 แก้ไขการคำนวณเพดานกราฟและระยะห่างแกน Y ให้เป็นจำนวนเต็ม
    double maxY = maxDistance > 0 ? (maxDistance * 1.3).ceilToDouble() : 5.0;
    double yInterval = maxY <= 5 ? 1.0 : (maxY / 5).ceilToDouble();
    double xInterval = chartDocs.length > 7 ? (chartDocs.length / 10).ceilToDouble() : 1.0;

    return Container(
      padding: const EdgeInsets.only(top: 24, bottom: 16, left: 8, right: 16),
      height: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1C6FA), width: 1.5),
      ),
      child: LineChart(
        LineChartData(
          maxY: maxY, 
          minY: 0,
          minX: 0,
          maxX: (chartDocs.length - 1).toDouble(),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => Colors.blueGrey.shade800.withOpacity(0.9),
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((LineBarSpot touchedSpot) {
                  int index = touchedSpot.x.toInt();
                  if (index < 0 || index >= chartDocs.length) return null;

                  final data = chartDocs[index].data() as Map<String, dynamic>;
                  final date = _parseDateTime(data['start_time']) ?? DateTime.now();
                  double distance = _parseDouble(data['distance_km']);
                  int duration = _parseInt(data['duration_minutes']);

                  String dateStr = DateFormat('dd/MM/yyyy').format(date);
                  String timeStr = DateFormat('HH:mm').format(date);

                  return LineTooltipItem(
                    'วันที่: $dateStr\nเวลา: $timeStr น.\nระยะทาง: ${distance.toStringAsFixed(2)} กม.\nระยะเวลา: ${_formatDuration(duration)}',
                    GoogleFonts.mitr(color: Colors.white, fontSize: 12),
                    textAlign: TextAlign.left,
                  );
                }).toList();
              },
            ),
          ),
          gridData: FlGridData(
            show: true, 
            drawVerticalLine: false,
            // 🟢 บังคับใช้ yInterval สำหรับเส้นตารางแนวนอน
            horizontalInterval: yInterval,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade100, strokeWidth: 1, dashArray: [5, 5]),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true, 
                reservedSize: 30,
                interval: xInterval, 
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < chartDocs.length) {
                    final data = chartDocs[index].data() as Map<String, dynamic>;
                    final date = _parseDateTime(data['start_time']) ?? DateTime.now();
                    String label = DateFormat('dd/MM').format(date);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0), 
                      child: Text(label, style: GoogleFonts.mitr(fontSize: 10, color: Colors.grey.shade500))
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true, 
                reservedSize: 45,
                // 🟢 บังคับใช้ yInterval สำหรับตัวเลขแกน Y
                interval: yInterval,
                getTitlesWidget: (value, meta) {
                  return Text("${value.toInt()} กม.", style: GoogleFonts.mitr(fontSize: 10, color: Colors.grey.shade400), textAlign: TextAlign.right);
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots, 
              isCurved: false, 
              color: const Color(0xFFAEDBFA), 
              barWidth: 2, 
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true, 
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 4, 
                  color: Colors.white, 
                  strokeWidth: 2, 
                  strokeColor: const Color(0xFFAEDBFA)
                )
              ),
              belowBarData: BarAreaData(show: true, color: const Color(0xFFAEDBFA).withOpacity(0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalkHistoryList(List<QueryDocumentSnapshot> docs) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        final date = _parseDateTime(data['start_time']) ?? DateTime.now();
        String name = data['name'] ?? 'เดินเล่น';
        
        double distance = _parseDouble(data['distance_km']);
        int duration = _parseInt(data['duration_minutes']);
        
        String formattedDate = DateFormat('dd/MM/yyyy HH:mm น.').format(date);
        
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
              Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Color(0xFFCDE5F7), shape: BoxShape.circle), child: const Icon(Icons.pets, color: Color(0xFF6DA2B8))),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.mitr(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(formattedDate, style: GoogleFonts.mitr(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text("${distance.toStringAsFixed(1)} กม.\n${_formatDuration(duration)}", textAlign: TextAlign.right, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF6DA2B8))),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String text) {
    return Center(child: Padding(padding: const EdgeInsets.all(20.0), child: Text(text, style: GoogleFonts.mitr(color: Colors.grey))));
  }
}