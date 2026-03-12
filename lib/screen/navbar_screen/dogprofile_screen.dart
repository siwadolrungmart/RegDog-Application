import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:regdogapp/component/upperbar.dart';
import 'package:regdogapp/component/bar.dart';
import 'package:regdogapp/screen/dog_list.dart';
import 'package:regdogapp/service/dogdatabase_service.dart';
import 'package:regdogapp/providers/current_dog_provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class DogProfilePage extends StatefulWidget {
  const DogProfilePage({super.key});

  @override
  State<DogProfilePage> createState() => _DogProfilePageState();
}

class _DogProfilePageState extends State<DogProfilePage> {
  int _currentIndex = 2;
  final DatabaseService _db = DatabaseService();
  bool isEditing = false;

  // Controllers and local states
  late TextEditingController nameController;
  late TextEditingController breedController;
  late TextEditingController microchipController;
  late TextEditingController pedigreeController;
  late TextEditingController diseasesController;
  String gender = '';
  DateTime? birthDate;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('th');
    nameController = TextEditingController();
    breedController = TextEditingController();
    microchipController = TextEditingController();
    pedigreeController = TextEditingController();
    diseasesController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncWithProvider();
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    breedController.dispose();
    microchipController.dispose();
    pedigreeController.dispose();
    diseasesController.dispose();
    super.dispose();
  }

  /// Sync ข้อมูลจาก provider ไปยัง state ตัวแปรและ controller
  void _syncWithProvider() {
    final provider = Provider.of<CurrentDogProvider>(context, listen: false);

    // ถ้ายังไม่มีข้อมูลเลย → โหลดสุนัขตัวแรกเป็น fallback เท่านั้น
    if (provider.currentDogId == null || provider.currentDogId!.isEmpty) {
      _loadFirstDogAsFallback();
    }

    // Sync ข้อมูลล่าสุดจาก provider
    _resetLocalFields();
  }

  Future<void> _loadFirstDogAsFallback() async {
    try {
      final dogs = await _db.getDogsByOwner('temp_user_123').first;
      if (dogs.docs.isNotEmpty) {
        final firstDoc = dogs.docs.first;
        final data = firstDoc.data() as Map<String, dynamic>;
        Provider.of<CurrentDogProvider>(context, listen: false)
            .selectDog(firstDoc.id, data);
        debugPrint("โหลดสุนัขตัวแรกอัตโนมัติ: ${data['name']}");
      }
    } catch (e) {
      debugPrint("โหลดสุนัขตัวแรกล้มเหลว: $e");
    }
  }

  void _resetLocalFields() {
    final provider = Provider.of<CurrentDogProvider>(context, listen: false);
    nameController.text = provider.dogName;
    breedController.text = provider.dogBreed;
    gender = provider.dogGender;
    birthDate = _parseThaiDate(provider.dogBirthDate);
    microchipController.text = provider.dogMicrochip;
    pedigreeController.text = provider.dogPedigree;
    diseasesController.text = provider.dogDiseases;

    setState(() {}); // บังคับ rebuild ถ้าจำเป็น
  }

  DateTime? _parseThaiDate(String dateStr) {
    if (dateStr == 'ไม่ทราบวันที่' || dateStr.isEmpty || dateStr == '') {
      return null;
    }

    try {
      final parts = dateStr.trim().split(' ');
      if (parts.length < 4) return null;

      final day = int.tryParse(parts[0]) ?? 1;
      final monthStr = parts[1];
      String yearStr = parts[3].replaceAll('พ.ศ.', '').trim();
      final year = (int.tryParse(yearStr) ?? 2500) - 543;

      final monthMap = {
        'มกราคม': 1,
        'กุมภาพันธ์': 2,
        'มีนาคม': 3,
        'เมษายน': 4,
        'พฤษภาคม': 5,
        'มิถุนายน': 6,
        'กรกฎาคม': 7,
        'สิงหาคม': 8,
        'กันยายน': 9,
        'ตุลาคม': 10,
        'พฤศจิกายน': 11,
        'ธันวาคม': 12,
      };
      final month = monthMap[monthStr] ?? 1;

      final parsed = DateTime(year, month, day);
      debugPrint("Parsed birthDate: $parsed from '$dateStr'");
      return parsed;
    } catch (e) {
      debugPrint("Parse วันที่ล้มเหลว: '$dateStr' → $e");
      return null;
    }
  }

  String _getFormattedBirthDate() {
    if (birthDate == null) return 'ไม่ทราบวันที่';
    final formatter = DateFormat('d MMMM', 'th');
    final thaiYear = birthDate!.year + 543;
    return '${formatter.format(birthDate!)} พ.ศ.$thaiYear';
  }

  String _getAge() {
    if (birthDate == null) return 'ไม่ทราบอายุ';
    final now = DateTime.now();
    int years = now.year - birthDate!.year;
    int months = now.month - birthDate!.month;
    if (now.day < birthDate!.day) months--;
    if (months < 0) {
      years--;
      months += 12;
    }
    return '$years ปี $months เดือน';
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: birthDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        birthDate = picked;
      });
    }
  }

  Future<void> _saveChanges() async {
    final provider = Provider.of<CurrentDogProvider>(context, listen: false);

    final success = await _db.updateDog(
      docId: provider.currentDogId!,
      name: nameController.text.trim(),
      breed: breedController.text.trim(),
      birthDate: birthDate,
      gender: gender,
      microchip: microchipController.text.trim(),
      pedigree: pedigreeController.text.trim(),
      diseases: diseasesController.text.trim(),
    );

    if (success && mounted) {
      final updatedData = {
        ...?provider.currentDogData,
        'name': nameController.text.trim(),
        'breed': breedController.text.trim(),
        if (birthDate != null) 'birthDate': Timestamp.fromDate(birthDate!),
        'gender': gender,
        'microchip': microchipController.text.trim(),
        'pedigree': pedigreeController.text.trim(),
        'diseases': diseasesController.text.trim(),
      };

      provider.selectDog(provider.currentDogId!, updatedData);
      setState(() {
        isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกข้อมูลสำเร็จ')),
      );
    }
  }

  void _cancelEditing() {
    _resetLocalFields();
    setState(() {
      isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _currentIndex,
        onItemTapped: (index) {
          setState(() => _currentIndex = index);
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            HomeTopBar(
              showProfile: true,
              onMenuTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DogListPage()),
                ).then((_) {
                  // เมื่อกลับมาจาก DogListPage → sync ใหม่
                  _syncWithProvider();
                });
              },
              onNotificationTap: () => debugPrint("Notification tapped"),
              onProfileTap: () => debugPrint("Profile tapped"),
            ),
            Expanded(
              child: Consumer<CurrentDogProvider>(
                builder: (context, provider, child) {
                  // Debug log ทุกครั้งที่ rebuild
                  debugPrint(
                      "Consumer rebuild → currentDogId: ${provider.currentDogId}, name: ${provider.dogName}");

                  if (provider.currentDogId == null ||
                      provider.currentDogId!.isEmpty ||
                      provider.currentDogData == null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("ยังไม่ได้เลือกน้องสุนัข"),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const DogListPage(),
                                ),
                              );
                            },
                            child: const Text("เลือกน้องหมา"),
                          ),
                        ],
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: const Color(0xFFCBE4F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ProfileHeader(
                            dogName: provider.dogName,
                            dogImage: provider.dogImage,
                            onEdit: () {
                              _resetLocalFields();
                              setState(() => isEditing = true);
                            },
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 20),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: const Color(0xFFCBE4F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Text(
                                    "ข้อมูลส่วนตัวสุนัข",
                                    style: GoogleFonts.mitr(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (!isEditing) ...[
                                  DogInfoRow(label: "ชื่อ:", value: provider.dogName),
                                  DogInfoRow(label: "เพศ:", value: provider.dogGender),
                                  DogInfoRow(label: "สายพันธุ์:", value: provider.dogBreed),
                                  DogInfoRow(label: "วันเกิด:", value: provider.dogBirthDate),
                                  DogInfoRow(label: "อายุ:", value: _getAge()),
                                  DogInfoRow(label: "เลขไมโครชิพ:", value: provider.dogMicrochip),
                                  DogInfoRow(
                                    label: "ใบเพ็ดดีกรี:",
                                    value: provider.dogPedigree,
                                    isLink: true,
                                  ),
                                  DogInfoRow(label: "โรคประจำตัว:", value: provider.dogDiseases),
                                ] else ...[
                                  // ส่วน edit mode เดิม (เหมือนเดิม แต่เพิ่ม trim() ใน save แล้ว)
                                  EditDogInfoRow(
                                    label: "ชื่อ:",
                                    child: TextField(controller: nameController),
                                  ),
                                  EditDogInfoRow(
                                    label: "เพศ:",
                                    child: DropdownButton<String>(
                                      value: gender,
                                      isExpanded: true,
                                      items: const [
                                        DropdownMenuItem(value: 'เพศผู้', child: Text('เพศผู้')),
                                        DropdownMenuItem(value: 'เพศเมีย', child: Text('เพศเมีย')),
                                      ],
                                      onChanged: (value) => setState(() => gender = value!),
                                    ),
                                  ),
                                  EditDogInfoRow(
                                    label: "สายพันธุ์:",
                                    child: TextField(controller: breedController),
                                  ),
                                  EditDogInfoRow(
                                    label: "วันเกิด:",
                                    child: GestureDetector(
                                      onTap: _pickBirthDate,
                                      child: AbsorbPointer(
                                        child: TextField(
                                          controller: TextEditingController(text: _getFormattedBirthDate()),
                                          decoration: const InputDecoration(
                                            suffixIcon: Icon(Icons.calendar_today),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  EditDogInfoRow(label: "อายุ:", child: Text(_getAge())),
                                  EditDogInfoRow(
                                    label: "เลขไมโครชิพ:",
                                    child: TextField(controller: microchipController),
                                  ),
                                  EditDogInfoRow(
                                    label: "ใบเพ็ดดีกรี:",
                                    child: TextField(controller: pedigreeController),
                                  ),
                                  EditDogInfoRow(
                                    label: "โรคประจำตัว:",
                                    child: TextField(controller: diseasesController),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      OutlinedButton(
                                        onPressed: _cancelEditing,
                                        child: const Text('ยกเลิก'),
                                      ),
                                      ElevatedButton(
                                        onPressed: _saveChanges,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.yellow[200],
                                        ),
                                        child: const Text('บันทึก ✓'),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// คลาสอื่น ๆ (ProfileHeader, DogInfoRow, EditDogInfoRow) เหมือนเดิม ไม่ต้องแก้

class ProfileHeader extends StatelessWidget {
  final String dogName;
  final String dogImage;
  final VoidCallback onEdit;

  // รับค่าผ่าน Constructor
  const ProfileHeader({
    required this.dogName,
    required this.dogImage,
    required this.onEdit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // กำหนดรูปภาพ ถ้ามีลิงก์ให้ใช้ NetworkImage ถ้าไม่มีให้ใช้รูป Default
    final imageProvider = (dogImage.isNotEmpty && dogImage.startsWith('http'))
        ? NetworkImage(dogImage)
        : const AssetImage('assets/images/dog.jpg') as ImageProvider;
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 55,
                backgroundColor: const Color(0xFFEEEEEE),
                backgroundImage: imageProvider, // ใช้ตัวแปรรูปภาพ
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF81AAB7),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Color(0xFF81AAB7),
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            dogName, // ใช้ตัวแปรชื่อที่รับมา
            style: GoogleFonts.mitr(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF75A4B2),
            ),
          ),
        ],
      ),
    );
  }
}

/// วิดเจ็ตสำหรับแสดงข้อมูลเป็นแถว พร้อม Divider ด้านล่าง
class DogInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLink;

  const DogInfoRow({
    required this.label,
    required this.value,
    this.isLink = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100, // Fix ความกว้างของ Label เพื่อให้ Value ตรงกันทุกบรรทัด
                child: Text(
                  label,
                  style: GoogleFonts.mitr(
                    color: const Color(0xFF81AAB7), // Label สีฟ้า
                    fontSize: 15,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.mitr(
                    color: Colors.black87,
                    fontSize: 15,
                    decoration: isLink ? TextDecoration.underline : TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(
          color: Color(0xFFEEEEEE), // Divider สีเทาอ่อน
          height: 1,
          thickness: 1,
        ),
      ],
    );
  }
}

class EditDogInfoRow extends StatelessWidget {
  final String label;
  final Widget child;

  const EditDogInfoRow({
    required this.label,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  label,
                  style: GoogleFonts.mitr(
                    color: const Color(0xFF81AAB7),
                    fontSize: 15,
                  ),
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
        const Divider(
          color: Color(0xFFEEEEEE),
          height: 1,
          thickness: 1,
        ),
      ],
    );
  }
}