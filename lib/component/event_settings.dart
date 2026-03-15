// ไฟล์: lib/component/event_settings.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// ==========================================
// 1. Data Model สำหรับเก็บข้อมูลการทำซ้ำ
// ==========================================
class RecurrenceData {
  final String repeatType; // 'none', 'daily', 'weekly', 'monthly', 'yearly'
  final int interval; // >= 1
  final List<int> weeklyDays; // 1=Mon, 7=Sun
  final String monthlyMode; // 'dayOfMonth' หรือ 'weekdayOfMonth'
  final DateTime? endDate; // เงื่อนไขหยุดแบบวันที่
  final int? count; // เงื่อนไขหยุดแบบจำนวนครั้ง

  RecurrenceData({
    required this.repeatType,
    required this.interval,
    required this.weeklyDays,
    this.monthlyMode = 'dayOfMonth',
    this.endDate,
    this.count,
  });
}

// ==========================================
// 2. Component: แจ้งเตือน (ReminderPicker)
// ==========================================
class ReminderPicker extends StatelessWidget {
  final int? selectedMinutes;
  final ValueChanged<int?> onChanged;

  const ReminderPicker({
    super.key,
    required this.selectedMinutes,
    required this.onChanged,
  });

  static const Map<String, int?> _reminderMap = {
    "ไม่มีการแจ้งเตือน": null,
    "เมื่อถึงเวลากิจกรรม": 0,
    "5 นาที ก่อนหน้า": 5,
    "10 นาที ก่อนหน้า": 10,
    "15 นาที ก่อนหน้า": 15,
    "30 นาที ก่อนหน้า": 30,
    "1 ชั่วโมง ก่อนหน้า": 60,
    "1 วัน ก่อนหน้า": 1440,
  };

  @override
  Widget build(BuildContext context) {
    String currentLabel = _reminderMap.entries
        .firstWhere((entry) => entry.value == selectedMinutes,
            orElse: () => const MapEntry("ไม่มีการแจ้งเตือน", null))
        .key;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!), 
        borderRadius: BorderRadius.circular(8)
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentLabel,
          isDense: true,
          isExpanded: true,
          items: _reminderMap.keys.map((label) => DropdownMenuItem(
            value: label, 
            child: Text(label, style: const TextStyle(fontSize: 13))
          )).toList(),
          onChanged: (val) {
            if (val != null) onChanged(_reminderMap[val]); 
          },
        ),
      ),
    );
  }
}

// ==========================================
// 3. Component: ทำซ้ำ (RecurrenceSection)
// ==========================================
class RecurrenceSection extends StatefulWidget {
  final Color labelColor;
  final Color primaryColor;
  final DateTime baseDate;
  final ValueChanged<RecurrenceData> onChanged;
  final RecurrenceData? initialData; 

  const RecurrenceSection({
    super.key,
    required this.labelColor,
    required this.primaryColor,
    required this.baseDate,
    required this.onChanged,
    this.initialData, 
  });

  @override
  State<RecurrenceSection> createState() => _RecurrenceSectionState();
}

class _RecurrenceSectionState extends State<RecurrenceSection> {
  String _selectedDropdown = "ไม่ทำซ้ำ";
  bool _isCustomMode = false;

  final List<String> _dayNamesFull = ["วันจันทร์", "วันอังคาร", "วันพุธ", "วันพฤหัสบดี", "วันศุกร์", "วันเสาร์", "วันอาทิตย์"];
  final List<String> _monthNamesShort = ["ม.ค.", "ก.พ.", "มี.ค.", "เม.ย.", "พ.ค.", "มิ.ย.", "ก.ค.", "ส.ค.", "ก.ย.", "ต.ค.", "พ.ย.", "ธ.ค."];
  final List<String> _dayNamesShort = ["จ.", "อ.", "พ.", "พฤ.", "ศ.", "ส.", "อา."];

  String _customRepeatUnit = "สัปดาห์"; 
  String _endCondition = "ไม่มีที่สิ้นสุด"; 
  
  List<bool> _weeklyDays = List.generate(7, (index) => false);
  DateTime? _repeatEndDate;
  final TextEditingController _intervalController = TextEditingController(text: "1");
  final TextEditingController _countController = TextEditingController(text: "10");

  final Map<String, String> _customUnitMap = {
    "วัน": "daily",
    "สัปดาห์": "weekly",
    "เดือน": "monthly",
    "ปี": "yearly",
  };

  String get _weeklyLabel => "ทุกสัปดาห์ใน${_dayNamesFull[widget.baseDate.weekday - 1]}";
  String get _monthlyLabel => "ทุกเดือนในวันที่ ${widget.baseDate.day}";
  String get _yearlyLabel => "ทุกปีในวันที่ ${widget.baseDate.day} ${_monthNamesShort[widget.baseDate.month - 1]}";

  List<String> get _dropdownOptions => [
    "ไม่ทำซ้ำ",
    "ทุกวัน",
    _weeklyLabel,
    _monthlyLabel,
    _yearlyLabel,
    "กำหนดเอง..."
  ];

  @override
  void initState() {
    super.initState();
    _intervalController.addListener(_notifyParent);
    _countController.addListener(_notifyParent);
    
    if (widget.initialData != null && widget.initialData!.repeatType != 'none') {
      final init = widget.initialData!;
      _intervalController.text = init.interval.toString();

      if (init.interval == 1 && init.endDate == null && init.count == null) {
        if (init.repeatType == 'daily') _selectedDropdown = "ทุกวัน";
        else if (init.repeatType == 'weekly' && init.weeklyDays.length == 1 && init.weeklyDays.first == widget.baseDate.weekday) _selectedDropdown = _weeklyLabel;
        else if (init.repeatType == 'monthly') _selectedDropdown = _monthlyLabel;
        else if (init.repeatType == 'yearly') _selectedDropdown = _yearlyLabel;
        else _selectedDropdown = "กำหนดเอง...";
      } else {
        _selectedDropdown = "กำหนดเอง...";
      }

      _isCustomMode = (_selectedDropdown == "กำหนดเอง...");

      if (init.repeatType == 'daily') _customRepeatUnit = "วัน";
      else if (init.repeatType == 'weekly') _customRepeatUnit = "สัปดาห์";
      else if (init.repeatType == 'monthly') _customRepeatUnit = "เดือน";
      else if (init.repeatType == 'yearly') _customRepeatUnit = "ปี";

      if (init.repeatType == 'weekly' && init.weeklyDays.isNotEmpty) {
        for (var day in init.weeklyDays) {
          if (day >= 1 && day <= 7) _weeklyDays[day - 1] = true;
        }
      } else {
        _weeklyDays[widget.baseDate.weekday - 1] = true;
      }

      if (init.endDate != null) {
        _endCondition = "ระบุวันที่";
        _repeatEndDate = init.endDate;
      } else if (init.count != null) {
        _endCondition = "ระบุจำนวนครั้ง";
        _countController.text = init.count.toString();
      } else {
        _endCondition = "ไม่มีที่สิ้นสุด";
      }

    } else {
      _weeklyDays[widget.baseDate.weekday - 1] = true;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _notifyParent());
  }

  @override
  void didUpdateWidget(covariant RecurrenceSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.baseDate != oldWidget.baseDate) {
      setState(() {
        if (!_isCustomMode) {
          if (_selectedDropdown.startsWith("ทุกสัปดาห์")) _selectedDropdown = _weeklyLabel;
          if (_selectedDropdown.startsWith("ทุกเดือน")) _selectedDropdown = _monthlyLabel;
          if (_selectedDropdown.startsWith("ทุกปี")) _selectedDropdown = _yearlyLabel;
        }
        _weeklyDays = List.generate(7, (index) => false);
        _weeklyDays[widget.baseDate.weekday - 1] = true;

        if (_repeatEndDate != null && _repeatEndDate!.isBefore(widget.baseDate)) {
          _repeatEndDate = widget.baseDate.add(const Duration(days: 1));
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _notifyParent());
    }
  }

  @override
  void dispose() {
    _intervalController.removeListener(_notifyParent);
    _countController.removeListener(_notifyParent);
    _intervalController.dispose();
    _countController.dispose();
    super.dispose();
  }

  // 🟢 ฟังก์ชันใหม่: จำลองหา "วันที่สิ้นสุดจริง" จากจำนวนครั้ง
  DateTime _calculateEndDateFromCount(DateTime start, String repeatType, int interval, List<int> weeklyDays, int count) {
    if (count <= 1) return start;

    if (repeatType == 'daily') {
      return start.add(Duration(days: (count - 1) * interval));
    } else if (repeatType == 'weekly') {
      DateTime current = start;
      int generated = 0;
      DateTime startMonday = start.subtract(Duration(days: start.weekday - 1));

      int safety = 0;
      while (generated < count && safety < 1000) {
        if (weeklyDays.isEmpty || weeklyDays.contains(current.weekday)) {
           DateTime currentMonday = current.subtract(Duration(days: current.weekday - 1));
           int weeksDiff = currentMonday.difference(startMonday).inDays ~/ 7;
           if (weeksDiff % interval == 0) {
             generated++;
             if (generated >= count) return current;
           }
        }
        current = current.add(const Duration(days: 1));
        safety++;
      }
      return current;
    } else if (repeatType == 'monthly') {
      int targetMonth = start.month + ((count - 1) * interval);
      int targetYear = start.year + ((targetMonth - 1) ~/ 12);
      int actualMonth = ((targetMonth - 1) % 12) + 1;
      int daysInTargetMonth = DateTime(targetYear, actualMonth + 1, 0).day;
      int clampedDay = start.day > daysInTargetMonth ? daysInTargetMonth : start.day;
      return DateTime(targetYear, actualMonth, clampedDay, start.hour, start.minute);
    } else if (repeatType == 'yearly') {
      int targetYear = start.year + ((count - 1) * interval);
      int daysInTargetMonth = DateTime(targetYear, start.month + 1, 0).day;
      int clampedDay = start.day > daysInTargetMonth ? daysInTargetMonth : start.day;
      return DateTime(targetYear, start.month, clampedDay, start.hour, start.minute);
    }
    return start;
  }

  void _notifyParent() {
    if (!_isCustomMode) {
      String rType = "none";
      int interval = 1;
      List<int> wDays = [];

      if (_selectedDropdown == "ทุกวัน") rType = "daily";
      else if (_selectedDropdown == _weeklyLabel) { rType = "weekly"; wDays = [widget.baseDate.weekday]; }
      else if (_selectedDropdown == _monthlyLabel) rType = "monthly";
      else if (_selectedDropdown == _yearlyLabel) rType = "yearly";

      widget.onChanged(RecurrenceData(
        repeatType: rType, interval: interval, weeklyDays: wDays, endDate: null, count: null,
      ));
      return;
    }

    int interval = int.tryParse(_intervalController.text) ?? 1;
    if (interval < 1) interval = 1;

    List<int> selectedDayNumbers = [];
    for (int i = 0; i < _weeklyDays.length; i++) {
      if (_weeklyDays[i]) selectedDayNumbers.add(i + 1);
    }
    if (_customUnitMap[_customRepeatUnit] == "weekly" && selectedDayNumbers.isEmpty) {
      selectedDayNumbers.add(widget.baseDate.weekday);
    }

    DateTime? finalEndDate;
    int? finalCount;

    if (_endCondition == "ระบุวันที่") {
      finalEndDate = _repeatEndDate;
    } else if (_endCondition == "ระบุจำนวนครั้ง") {
      finalCount = int.tryParse(_countController.text) ?? 1;
      if (finalCount < 1) finalCount = 1;
      
      // 🟢 [อัปเดตแก้อาการปฏิทินพัง] บังคับสร้าง End Date ซ้อนเข้าไปด้วย เพื่อให้หน้า Calendar นำไปขีดเส้นขอบเขตได้
      finalEndDate = _calculateEndDateFromCount(
         widget.baseDate,
         _customUnitMap[_customRepeatUnit] ?? "daily",
         interval,
         selectedDayNumbers,
         finalCount
      );
    }

    widget.onChanged(RecurrenceData(
      repeatType: _customUnitMap[_customRepeatUnit] ?? "none",
      interval: interval,
      weeklyDays: selectedDayNumbers,
      endDate: finalEndDate, 
      count: finalCount,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFormRow("ทำซ้ำ:", _buildMainDropdown()),
        if (_isCustomMode) ...[
          _buildDivider(),
          _buildCustomIntervalUI(),
          if (_customRepeatUnit == "สัปดาห์") ...[
            const SizedBox(height: 12),
            _buildCustomWeeklyDaysUI(),
          ],
          _buildDivider(),
          _buildFormRow("สิ้นสุด:", _buildEndConditionDropdown()),
          if (_endCondition == "ระบุวันที่") ...[
            const SizedBox(height: 8),
            _buildFormRow("วันที่สิ้นสุด:", _buildEndDatePicker(context)),
          ],
          if (_endCondition == "ระบุจำนวนครั้ง") ...[
            const SizedBox(height: 8),
            _buildFormRow("จำนวนครั้ง:", _buildCountInput()),
          ]
        ],
      ],
    );
  }

  // --- UI Helpers ---
  Widget _buildFormRow(String label, Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [SizedBox(width: 100, child: Text(label, style: GoogleFonts.inter(color: widget.labelColor, fontSize: 14))), Expanded(child: child)],
      ),
    );
  }

  Widget _buildDivider() => const Divider(height: 20, thickness: 1, color: Color(0xFFF0F0F0));

  Widget _buildMainDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 5),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedDropdown, isDense: true, isExpanded: true,
          items: _dropdownOptions.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: (val) {
            setState(() { _selectedDropdown = val!; _isCustomMode = (_selectedDropdown == "กำหนดเอง..."); });
            _notifyParent();
          },
        ),
      ),
    );
  }

  Widget _buildCustomIntervalUI() {
    return Row(
      children: [
        SizedBox(width: 100, child: Text("ทำซ้ำทุกๆ:", style: GoogleFonts.inter(color: widget.labelColor, fontSize: 14))),
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                  child: TextField(
                    controller: _intervalController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(border: InputBorder.none, isDense: true), style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _customRepeatUnit, isDense: true, isExpanded: true,
                      items: _customUnitMap.keys.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (val) { setState(() => _customRepeatUnit = val!); _notifyParent(); },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomWeeklyDaysUI() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(7, (i) => _buildDayToggle(i))),
    );
  }

  Widget _buildDayToggle(int index) {
    bool isSelected = _weeklyDays[index];
    return GestureDetector(
      onTap: () {
        if (isSelected && _weeklyDays.where((e) => e).length == 1) return;
        setState(() => _weeklyDays[index] = !isSelected);
        _notifyParent();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: isSelected ? widget.primaryColor : Colors.grey[100], shape: BoxShape.circle),
        child: Text(_dayNamesShort[index], style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontSize: 10)),
      ),
    );
  }

  Widget _buildEndConditionDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _endCondition, isDense: true, isExpanded: true,
          items: ["ไม่มีที่สิ้นสุด", "ระบุวันที่", "ระบุจำนวนครั้ง"].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: (val) { setState(() => _endCondition = val!); _notifyParent(); },
        ),
      ),
    );
  }

  Widget _buildEndDatePicker(BuildContext context) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context, initialDate: _repeatEndDate ?? widget.baseDate.add(const Duration(days: 1)),
          firstDate: widget.baseDate, lastDate: DateTime(2100),
        );
        if (date != null) { setState(() => _repeatEndDate = date); _notifyParent(); }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(_repeatEndDate == null ? "เลือกวันสิ้นสุด" : DateFormat('dd/MM/yyyy').format(_repeatEndDate!), style: GoogleFonts.inter(color: Colors.blue)),
      ),
    );
  }

  Widget _buildCountInput() {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
            child: TextField(
              controller: _countController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(border: InputBorder.none, isDense: true), style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text("ครั้ง", style: GoogleFonts.inter(fontSize: 14)),
      ],
    );
  }
}