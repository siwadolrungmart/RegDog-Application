import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:regdogapp/providers/current_dog_provider.dart';

class WeightView extends StatefulWidget {
  const WeightView({super.key});

  @override
  State<WeightView> createState() => _WeightViewState();
}

class _WeightViewState extends State<WeightView> {
  String _timeFilter = '6_months'; 
  int? _touchedIndex; 

  DateTime _getStartDate() {
    final now = DateTime.now();
    switch (_timeFilter) {
      case '1_month': return DateTime(now.year, now.month - 1, now.day);
      case '6_months': return DateTime(now.year, now.month - 6, now.day);
      case '1_year': return DateTime(now.year - 1, now.month, now.day);
      default: return DateTime(now.year, now.month - 6, now.day);
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
          .collection('dogs')
          .doc(currentDogId)
          .collection('weight_history')
          .orderBy('recordedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("เกิดข้อผิดพลาดในการโหลดข้อมูล", style: GoogleFonts.mitr(color: Colors.red)));
        }

        final startDate = _getStartDate();
        final endDate = DateTime.now(); 
        
        List<QueryDocumentSnapshot> filteredDocs = [];

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final date = _parseDateTime(data['recordedAt']);

            if (date != null && date.isAfter(startDate) && !date.isAfter(endDate)) {
              filteredDocs.add(doc);
            }
          }
        }

        List<QueryDocumentSnapshot> chartDocs = List.from(filteredDocs);
        chartDocs.sort((a, b) {
          final dateA = _parseDateTime((a.data() as Map<String, dynamic>)['recordedAt']) ?? DateTime.now();
          final dateB = _parseDateTime((b.data() as Map<String, dynamic>)['recordedAt']) ?? DateTime.now();
          return dateA.compareTo(dateB); 
        });

        double displayWeight = 0;
        double displayPreviousWeight = 0;

        if (chartDocs.isNotEmpty) {
          int targetIndex = chartDocs.length - 1;

          if (_touchedIndex != null && _touchedIndex! >= 0 && _touchedIndex! < chartDocs.length) {
            targetIndex = _touchedIndex!;
          }

          displayWeight = _parseDouble((chartDocs[targetIndex].data() as Map<String, dynamic>)['weight']);
          
          if (targetIndex > 0) {
            displayPreviousWeight = _parseDouble((chartDocs[targetIndex - 1].data() as Map<String, dynamic>)['weight']);
          } else {
            displayPreviousWeight = displayWeight; 
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTimeFilterDropdown(),
              const SizedBox(height: 16),
              _buildSummaryCard(displayWeight, displayPreviousWeight, _touchedIndex != null), 
              const SizedBox(height: 30),
              _buildWeightChart(chartDocs), 
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text("ประวัติน้ำหนักย้อนหลัง", style: GoogleFonts.mitr(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
              ),
              const SizedBox(height: 16),
              if (filteredDocs.isNotEmpty)
                _buildWeightHistoryList(filteredDocs)
              else
                _buildEmptyState("ไม่มีประวัติน้ำหนักในช่วงเวลานี้"),
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
            DropdownMenuItem(value: '1_month', child: Center(child: Text("1 เดือนย้อนหลัง"))),
            DropdownMenuItem(value: '6_months', child: Center(child: Text("6 เดือนย้อนหลัง"))),
            DropdownMenuItem(value: '1_year', child: Center(child: Text("1 ปีย้อนหลัง"))),
          ], 
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _timeFilter = value;
                _touchedIndex = null; 
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(double displayWeight, double previousWeight, bool isViewingPast) {
    double diff = displayWeight - previousWeight;
    String diffText = "";
    Color diffColor = Colors.grey;
    IconData? diffIcon;

    if (diff > 0) {
      diffText = "+${diff.toStringAsFixed(1)} กก.";
      diffColor = Colors.red.shade400;
      diffIcon = Icons.trending_up;
    } else if (diff < 0) {
      diffText = "${diff.toStringAsFixed(1)} กก.";
      diffColor = Colors.green.shade500;
      diffIcon = Icons.trending_down;
    } else {
      diffText = "คงที่";
      diffColor = Colors.grey.shade600;
      diffIcon = Icons.trending_flat;
    }

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
                  Text(displayWeight > 0 ? NumberFormat('#,##0.0').format(displayWeight) : "-", style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(width: 4),
                  Text("กก.", style: GoogleFonts.mitr(fontSize: 16, color: Colors.black54)),
                ],
              ),
              Text(isViewingPast ? "น้ำหนักที่เลือก" : "น้ำหนักล่าสุด", style: GoogleFonts.mitr(fontSize: 14, color: const Color(0xFF6DA2B8))),
            ],
          ),
          Container(width: 1, height: 50, color: Colors.grey.shade300),
          Column(
            children: [
              Row(
                children: [
                  if (diffIcon != null && displayWeight > 0) Icon(diffIcon, color: diffColor, size: 20),
                  const SizedBox(width: 4),
                  Text(displayWeight > 0 ? diffText : "-", style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: diffColor)),
                ],
              ),
              const SizedBox(height: 4),
              Text("เทียบครั้งก่อนหน้า", style: GoogleFonts.mitr(fontSize: 14, color: const Color(0xFF6DA2B8))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeightChart(List<QueryDocumentSnapshot> chartDocs) {
    if (chartDocs.isEmpty) {
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

    List<FlSpot> spots = [];
    double maxWeight = 0;
    double minWeight = double.infinity;

    for (int i = 0; i < chartDocs.length; i++) {
      final data = chartDocs[i].data() as Map<String, dynamic>;
      double weight = _parseDouble(data['weight']);
      spots.add(FlSpot(i.toDouble(), weight));
      
      if (weight > maxWeight) maxWeight = weight;
      if (weight < minWeight) minWeight = weight;
    }

    if (minWeight == double.infinity) minWeight = 0;

    double range = maxWeight - minWeight;
    double maxY = (maxWeight + (range > 0 ? range * 0.3 : 2)).ceilToDouble();
    double minY = (minWeight - (range > 0 ? range * 0.3 : 2)).floorToDouble();
    if (minY < 0) minY = 0; 

    double yInterval = range <= 5 ? 1.0 : (range / 5).ceilToDouble();
    if (yInterval == 0) yInterval = 1.0;

    double xInterval = chartDocs.length > 7 ? (chartDocs.length / 5).ceilToDouble() : 1.0;

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
          // 🟢 ใช้ clipData.all(false) เพื่อไม่ให้จุดขอบกราฟโดนตัดขอบ แทนการขยาย minX, maxX
          clipData: const FlClipData.none(),
          maxY: maxY, 
          minY: minY,
          minX: 0,
          // ป้องกันกรณีมีข้อมูลจุดเดียวแล้วกราฟ Error
          maxX: chartDocs.length > 1 ? (chartDocs.length - 1).toDouble() : 1.0, 
          lineTouchData: LineTouchData(
            touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
              if (!event.isInterestedForInteractions || touchResponse == null || touchResponse.lineBarSpots == null || touchResponse.lineBarSpots!.isEmpty) {
                if (event is FlTapUpEvent) {
                  setState(() => _touchedIndex = null);
                }
                return;
              }
              int newIndex = touchResponse.lineBarSpots!.first.x.toInt();
              if (_touchedIndex != newIndex) {
                setState(() => _touchedIndex = newIndex);
              }
            },
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => Colors.blueGrey.shade800.withOpacity(0.9),
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((LineBarSpot touchedSpot) {
                  int index = touchedSpot.x.toInt();
                  if (index < 0 || index >= chartDocs.length) return null;

                  final data = chartDocs[index].data() as Map<String, dynamic>;
                  final date = _parseDateTime(data['recordedAt']) ?? DateTime.now();
                  double weight = _parseDouble(data['weight']);

                  String dateStr = DateFormat('dd/MM/yyyy').format(date);
                  String timeStr = DateFormat('HH:mm').format(date);

                  return LineTooltipItem(
                    'วันที่: $dateStr\nเวลา: $timeStr น.\nน้ำหนัก: ${weight.toStringAsFixed(2)} กก.',
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
                  // 🟢 ดักเพื่อไม่ให้พยายามวาดค่าที่เป็นจุดทศนิยม ป้องกันข้อความซ้อนกัน
                  if (value != value.toInt()) return const SizedBox.shrink();

                  int index = value.toInt();
                  if (index >= 0 && index < chartDocs.length) {
                    final data = chartDocs[index].data() as Map<String, dynamic>;
                    final date = _parseDateTime(data['recordedAt']) ?? DateTime.now();
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
                interval: yInterval,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text("${value.toInt()}", style: GoogleFonts.mitr(fontSize: 10, color: Colors.grey.shade400), textAlign: TextAlign.right),
                  );
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
              isCurved: true, 
              color: const Color(0xFFF6A0C2), 
              barWidth: 3, 
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true, 
                getDotPainter: (spot, percent, barData, index) {
                  bool isTouched = _touchedIndex == index;
                  return FlDotCirclePainter(
                    radius: isTouched ? 7 : 5, 
                    color: isTouched ? const Color(0xFFF6A0C2) : Colors.white, 
                    strokeWidth: 2, 
                    strokeColor: const Color(0xFFF6A0C2)
                  );
                }
              ),
              belowBarData: BarAreaData(
                show: true, 
                color: const Color(0xFFF6A0C2).withOpacity(0.15)
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightHistoryList(List<QueryDocumentSnapshot> docs) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final data = docs[index].data() as Map<String, dynamic>;
        final date = _parseDateTime(data['recordedAt']) ?? DateTime.now();
        
        double weight = _parseDouble(data['weight']);
        String formattedDate = DateFormat('dd/MM/yyyy เวลา HH:mm น.').format(date);

        double diff = 0;
        if (index < docs.length - 1) {
          final prevData = docs[index + 1].data() as Map<String, dynamic>;
          double prevWeight = _parseDouble(prevData['weight']);
          diff = weight - prevWeight;
        }
        
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
              Container(
                padding: const EdgeInsets.all(10), 
                decoration: BoxDecoration(color: Colors.pink.shade50, shape: BoxShape.circle), 
                child: Icon(Icons.monitor_weight_rounded, color: Colors.pink.shade300)
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text("${weight.toStringAsFixed(1)} กก.", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                        if (index < docs.length - 1) ...[
                          const SizedBox(width: 8),
                          Icon(
                            diff > 0 ? Icons.arrow_upward : (diff < 0 ? Icons.arrow_downward : Icons.horizontal_rule),
                            size: 14,
                            color: diff > 0 ? Colors.red.shade400 : (diff < 0 ? Colors.green.shade500 : Colors.grey),
                          ),
                          Text(
                            diff != 0 ? "${diff > 0 ? '+' : ''}${diff.toStringAsFixed(1)}" : "",
                            style: GoogleFonts.inter(fontSize: 12, color: diff > 0 ? Colors.red.shade400 : Colors.green.shade500),
                          ),
                        ]
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(formattedDate, style: GoogleFonts.mitr(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ),
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