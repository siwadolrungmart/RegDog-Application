import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

class DogProfilePage extends StatefulWidget {
  const DogProfilePage({super.key});

  @override
  State<DogProfilePage> createState() => _DogProfilePageState();
}

class _DogProfilePageState extends State<DogProfilePage> {
  int _currentIndex = 2;
  final DatabaseService _db = DatabaseService();
  bool isEditing = false;
  bool isLoading = false;

  late TextEditingController nameController;
  late TextEditingController breedController;
  late TextEditingController microchipController;
  late TextEditingController diseasesController;
  late TextEditingController weightController; 
  late TextEditingController birthDateController; 
  late TextEditingController ageController; // 🟢 เพิ่ม Controller สำหรับอายุ

  String gender = '';
  DateTime? birthDate;

  File? _newProfileImage;
  File? _newPedigreeFile;
  String? _newPedigreeFileName;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('th');
    
    // 🟢 กำหนดค่า Controller ทั้งหมดก่อน เพื่อป้องกัน LateInitializationError
    nameController = TextEditingController();
    breedController = TextEditingController();
    microchipController = TextEditingController();
    diseasesController = TextEditingController();
    weightController = TextEditingController(); 
    birthDateController = TextEditingController(); 
    ageController = TextEditingController();

    // 🟢 แล้วค่อยสั่งดึงข้อมูล
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncWithProvider();
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    breedController.dispose();
    microchipController.dispose();
    diseasesController.dispose();
    weightController.dispose(); 
    birthDateController.dispose(); 
    ageController.dispose(); // 🟢 อย่าลืม dispose
    super.dispose();
  }

  void _syncWithProvider() {
    final provider = Provider.of<CurrentDogProvider>(context, listen: false);

    if (provider.currentDogId == null || provider.currentDogId!.isEmpty) {
      _loadFirstDogAsFallback();
    }

    _resetLocalFields();
  }

  Future<void> _loadFirstDogAsFallback() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final dogs = await _db.getDogsByOwner(user.uid).first;
      if (dogs.docs.isNotEmpty) {
        final firstDoc = dogs.docs.first;
        final data = firstDoc.data() as Map<String, dynamic>;

        Provider.of<CurrentDogProvider>(
          context,
          listen: false,
        ).selectDog(firstDoc.id, data);

        if (mounted) {
          _resetLocalFields();
        }
      }
    } catch (e) {
      debugPrint("โหลดสุนัขตัวแรกล้มเหลว: $e");
    }
  }

  void _resetLocalFields() {
    if (!mounted) return; // 🟢 ป้องกัน Error กรณี Widget ถูกทำลายไปแล้ว

    final provider = Provider.of<CurrentDogProvider>(context, listen: false);
    nameController.text = provider.dogName;
    breedController.text = provider.dogBreed;
    gender = provider.dogGender;

    final rawData = provider.currentDogData ?? {};
    if (rawData['birthDate'] is Timestamp) {
      birthDate = (rawData['birthDate'] as Timestamp).toDate();
    } else {
      birthDate = null;
    }

    microchipController.text = provider.dogMicrochip;
    diseasesController.text = provider.dogDiseases;

    final currentWeight = rawData['weight'];
    weightController.text = currentWeight != null ? currentWeight.toString() : '';
    
    birthDateController.text = _getFormattedBirthDate(); 
    ageController.text = _getAge(); // 🟢 เซ็ตค่าอายุเริ่มต้นให้ Controller

    _newProfileImage = null;
    _newPedigreeFile = null;
    _newPedigreeFileName = null;

    setState(() {});
  }

  String _getFormattedBirthDate() {
    if (birthDate == null) return 'ไม่ทราบวันที่';
    return DateFormat('d MMMM yyyy', 'th').format(birthDate!);
  }

  String _getAge() {
    if (birthDate == null) return 'ไม่ทราบอายุ';
    final now = DateTime.now();

    int years = now.year - birthDate!.year;
    int months = now.month - birthDate!.month;
    int days = now.day - birthDate!.day;

    if (days < 0) {
      months--;
      int prevMonth = now.month == 1 ? 12 : now.month - 1;
      int prevYear = now.month == 1 ? now.year - 1 : now.year;
      int daysInPrevMonth = DateTime(prevYear, prevMonth + 1, 0).day;
      days += daysInPrevMonth;
    }

    if (months < 0) {
      years--;
      months += 12;
    }

    List<String> ageParts = [];
    if (years > 0) ageParts.add('$years ปี');
    if (months > 0) ageParts.add('$months เดือน');
    if (days > 0) ageParts.add('$days วัน');

    if (ageParts.isEmpty) return 'เกิดวันนี้';
    return ageParts.join(' ');
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
        birthDateController.text = _getFormattedBirthDate(); 
        ageController.text = _getAge(); // 🟢 อัปเดตอายุทันทีเมื่อเลือกวันเกิด
      });
    }
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      setState(() {
        _newProfileImage = file;
      });
    }
  }

  Future<void> _pickPedigreeFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      setState(() {
        _newPedigreeFile = file;
        _newPedigreeFileName = result.files.single.name;
      });
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(color: Colors.red)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  Future<String?> _uploadFile(File file, String folder) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final ref = FirebaseStorage.instance.ref().child('$folder/$fileName');
      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } on FirebaseException catch (e) {
      debugPrint("Firebase Storage Error: ${e.code} - ${e.message}");
      if (mounted) {
        _showErrorDialog(
          "Firebase Error (${e.code})",
          e.message ?? "เกิดข้อผิดพลาดจาก Firebase",
        );
      }
      return null;
    } catch (e) {
      debugPrint("Upload Error: $e");
      if (mounted) {
        _showErrorDialog("เกิดข้อผิดพลาด", e.toString());
      }
      return null;
    }
  }

  Future<void> _saveChanges() async {
    final provider = Provider.of<CurrentDogProvider>(context, listen: false);

    setState(() => isLoading = true);

    String finalImageUrl = provider.dogImage;
    String finalPedigreeUrl = provider.dogPedigree;

    if (_newProfileImage != null) {
      final url = await _uploadFile(_newProfileImage!, 'dog_profiles');
      if (url != null) finalImageUrl = url;
    }

    if (_newPedigreeFile != null) {
      final url = await _uploadFile(_newPedigreeFile!, 'dog_pedigrees');
      if (url != null) finalPedigreeUrl = url;
    }

    double? newWeightValue;
    if (weightController.text.trim().isNotEmpty) {
      newWeightValue = double.tryParse(weightController.text.trim());
    }

    final success = await _db.updateDog(
      docId: provider.currentDogId!,
      name: nameController.text.trim(),
      breed: breedController.text.trim(),
      birthDate: birthDate,
      gender: gender,
      microchip: microchipController.text.trim(),
      diseases: diseasesController.text.trim(),
      photoUrl: finalImageUrl,
      pedigree: finalPedigreeUrl,
      weight: newWeightValue, 
    );

    if (success && mounted) {
      final oldWeight = provider.currentDogData?['weight'];
      if (newWeightValue != null && newWeightValue != oldWeight) {
        await _db.recordWeightHistory(provider.currentDogId!, newWeightValue);
      }

      final updatedData = {
        ...?provider.currentDogData,
        'name': nameController.text.trim(),
        'breed': breedController.text.trim(),
        if (birthDate != null) 'birthDate': Timestamp.fromDate(birthDate!),
        'gender': gender,
        'microchip': microchipController.text.trim(),
        'diseases': diseasesController.text.trim(),
        'photoUrl': finalImageUrl,
        'pedigree': finalPedigreeUrl,
        if (newWeightValue != null)
          'weight': newWeightValue, 
      };

      provider.selectDog(provider.currentDogId!, updatedData);
      setState(() {
        isEditing = false;
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('บันทึกข้อมูลสำเร็จ')));
    } else {
      setState(() => isLoading = false);
    }
  }

  void _cancelEditing() {
    _resetLocalFields();
    setState(() {
      isEditing = false;
    });
  }

  void _showWeightHistoryBottomSheet(String dogId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
         
          height: MediaQuery.of(context).size.height * 0.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ประวัติน้ำหนัก',
                    style: GoogleFonts.mitr(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _db.getWeightHistory(dogId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text('ยังไม่มีประวัติน้ำหนัก'),
                      );
                    }

                    final docs = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final weight = data['weight'];
                        final timestamp = data['recordedAt'] as Timestamp?;
                        final dateStr = timestamp != null
                            ? DateFormat(
                                'd MMM yyyy เวลา HH:mm',
                                'th',
                              ).format(timestamp.toDate())
                            : 'ไม่ระบุเวลา';

                        return ListTile(
                          leading: const Icon(
                            Icons.monitor_weight,
                            color: Color(0xFF75A4B2),
                          ),
                          title: Text(
                            '$weight กก.',
                            style: GoogleFonts.mitr(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            dateStr,
                            style: GoogleFonts.mitr(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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
        child: Stack(
          children: [
            Column(
              children: [
                HomeTopBar(
                  showProfile: true,
                  onMenuTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DogListPage(),
                      ),
                    ).then((_) {
                      _syncWithProvider();
                    });
                  },
                  onNotificationTap: () => debugPrint("Notification tapped"),
                  onProfileTap: () => debugPrint("Profile tapped"),
                ),
                Expanded(
                  child: Consumer<CurrentDogProvider>(
                    builder: (context, provider, child) {
                      if (provider.currentDogId == null ||
                          provider.currentDogId!.isEmpty ||
                          provider.currentDogData == null) {
                        return const Center(child: Text("กำลังโหลดข้อมูล..."));
                      }

                      final currentWeight = provider.currentDogData?['weight'];

                      return SingleChildScrollView(
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.all(20),
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
                                localImage: _newProfileImage,
                                isEditing: isEditing,
                                onEditToggle: () {
                                  _resetLocalFields();
                                  setState(() => isEditing = true);
                                },
                                onPickImage: _pickProfileImage,
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 20),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: const Color(0xFFCBE4F0),
                                  ),
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
                                      DogInfoRow(
                                        label: "ชื่อ:",
                                        value: provider.dogName,
                                      ),
                                      DogInfoRow(
                                        label: "เพศ:",
                                        value: provider.dogGender,
                                      ),
                                      DogInfoRow(
                                        label: "สายพันธุ์:",
                                        value: provider.dogBreed,
                                      ),
                                      DogInfoRow(
                                        label: "วันเกิด:",
                                        value: _getFormattedBirthDate(),
                                      ),
                                      DogInfoRow(
                                        label: "อายุ:",
                                        value: _getAge(),
                                      ),

                                      Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10.0,
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                SizedBox(
                                                  width: 100,
                                                  child: Text(
                                                    "น้ำหนัก:",
                                                    style: GoogleFonts.mitr(
                                                      color: const Color(
                                                        0xFF81AAB7,
                                                      ),
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Row(
                                                    children: [
                                                      Text(
                                                        currentWeight != null
                                                            ? "$currentWeight กก."
                                                            : "ไม่ระบุ",
                                                        style: GoogleFonts.mitr(
                                                          color: Colors.black87,
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      GestureDetector(
                                                        onTap: () =>
                                                            _showWeightHistoryBottomSheet(
                                                              provider
                                                                  .currentDogId!,
                                                            ),
                                                        child: const Icon(
                                                          Icons.history,
                                                          color: Colors.grey,
                                                          size: 20,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Divider(
                                            color: Color(0xFFEEEEEE),
                                            height: 1,
                                            thickness: 1,
                                          ),
                                        ],
                                      ),

                                      DogInfoRow(
                                        label: "เลขไมโครชิพ:",
                                        value: provider.dogMicrochip,
                                      ),
                                      DogInfoRow(
                                        label: "ใบเพ็ดดีกรี:",
                                        value: provider.dogPedigree.isNotEmpty
                                            ? "ดูเอกสารแนบ"
                                            : "-",
                                        isLink: provider.dogPedigree.isNotEmpty,
                                      ),
                                      DogInfoRow(
                                        label: "โรคประจำตัว:",
                                        value: provider.dogDiseases,
                                      ),
                                    ] else ...[
                                      EditDogInfoRow(
                                        label: "ชื่อ:",
                                        child: TextField(
                                          controller: nameController,
                                        ),
                                      ),
                                      EditDogInfoRow(
                                        label: "เพศ:",
                                        child: DropdownButton<String>(
                                          value: gender.isEmpty
                                              ? 'เพศผู้'
                                              : gender,
                                          isExpanded: true,
                                          items: const [
                                            DropdownMenuItem(
                                              value: 'เพศผู้',
                                              child: Text('เพศผู้'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'เพศเมีย',
                                              child: Text('เพศเมีย'),
                                            ),
                                          ],
                                          onChanged: (value) =>
                                              setState(() => gender = value!),
                                        ),
                                      ),
                                      EditDogInfoRow(
                                        label: "สายพันธุ์:",
                                        child: TextField(
                                          controller: breedController,
                                        ),
                                      ),
                                      EditDogInfoRow(
                                        label: "วันเกิด:",
                                        child: GestureDetector(
                                          onTap: _pickBirthDate,
                                          child: AbsorbPointer(
                                            child: TextField(
                                              controller: birthDateController, 
                                              decoration: const InputDecoration(
                                                suffixIcon: Icon(
                                                  Icons.calendar_today,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      
                                      // 🟢 แก้ไขช่องอายุให้ใช้ Controller แบบอ่านอย่างเดียว
                                      EditDogInfoRow(
                                        label: "อายุ:",
                                        child: TextField(
                                          controller: ageController,
                                          readOnly: true, 
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide.none,
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                            hintText: 'ระบบคำนวณให้อัตโนมัติ',
                                            fillColor: Colors.grey.shade100,
                                            filled: true,
                                          ),
                                        ),
                                      ),

                                      EditDogInfoRow(
                                        label: "น้ำหนัก (กก.):",
                                        child: TextField(
                                          controller: weightController,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                              RegExp(r'^\d*\.?\d*'),
                                            ),
                                          ],
                                          decoration: const InputDecoration(
                                            hintText: 'เช่น 15.5',
                                          ),
                                        ),
                                      ),
                                      EditDogInfoRow(
                                        label: "เลขไมโครชิพ:",
                                        child: TextField(
                                          controller: microchipController,
                                        ),
                                      ),
                                      EditDogInfoRow(
                                        label: "ใบเพ็ดดีกรี:",
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                _newPedigreeFileName ??
                                                    (provider
                                                            .dogPedigree
                                                            .isNotEmpty
                                                        ? "มีเอกสารเดิมแล้ว"
                                                        : "ยังไม่มีเอกสาร"),
                                                style: TextStyle(
                                                  color:
                                                      _newPedigreeFile != null
                                                      ? Colors.green
                                                      : Colors.black54,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: _pickPedigreeFile,
                                              icon: const Icon(
                                                Icons.upload_file,
                                                color: Color(0xFF75A4B2),
                                              ),
                                              tooltip: 'อัปโหลดเอกสาร',
                                            ),
                                          ],
                                        ),
                                      ),
                                      EditDogInfoRow(
                                        label: "โรคประจำตัว:",
                                        child: TextField(
                                          controller: diseasesController,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          OutlinedButton(
                                            onPressed: _cancelEditing,
                                            child: const Text('ยกเลิก'),
                                          ),
                                          ElevatedButton(
                                            onPressed: _saveChanges,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.yellow[200],
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
          ],
        ),
      ),
    );
  }
}

// ------------------------------------
// COMPONENTS
// ------------------------------------
class ProfileHeader extends StatelessWidget {
  final String dogName;
  final String dogImage;
  final File? localImage;
  final bool isEditing;
  final VoidCallback onEditToggle;
  final VoidCallback onPickImage;

  const ProfileHeader({
    required this.dogName,
    required this.dogImage,
    required this.onEditToggle,
    required this.onPickImage,
    this.localImage,
    this.isEditing = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider imageProvider;
    if (localImage != null) {
      imageProvider = FileImage(localImage!);
    } else if (dogImage.isNotEmpty && dogImage.startsWith('http')) {
      imageProvider = NetworkImage(dogImage);
    } else {
      imageProvider = const AssetImage('assets/dog.png');
    }

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 55,
                backgroundColor: const Color(0xFFEEEEEE),
                backgroundImage: imageProvider,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: isEditing ? onPickImage : onEditToggle,
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
                    child: Icon(
                      isEditing ? Icons.camera_alt : Icons.edit,
                      color: const Color(0xFF81AAB7),
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            dogName,
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
                width: 100,
                child: Text(
                  label,
                  style: GoogleFonts.mitr(
                    color: const Color(0xFF81AAB7),
                    fontSize: 15,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.mitr(
                    color: isLink ? Colors.blue : Colors.black87,
                    fontSize: 15,
                    decoration: isLink
                        ? TextDecoration.underline
                        : TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(color: Color(0xFFEEEEEE), height: 1, thickness: 1),
      ],
    );
  }
}

class EditDogInfoRow extends StatelessWidget {
  final String label;
  final Widget child;

  const EditDogInfoRow({required this.label, required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
        const Divider(color: Color(0xFFEEEEEE), height: 1, thickness: 1),
      ],
    );
  }
}
