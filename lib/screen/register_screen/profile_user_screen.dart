import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:regdogapp/component/upperbar.dart';
import 'package:regdogapp/component/bar.dart';
import 'package:regdogapp/screen/dog_list.dart';
// 🟢 เพิ่ม Import หน้า Login
import 'package:regdogapp/screen/login_screen.dart'; 

class UserProfileScreen extends StatefulWidget {
  // 🟢 1. เพิ่มตัวแปรสำหรับกำหนดการแสดงผล Bottom Bar
  final bool showBottomBar;

  const UserProfileScreen({
    super.key,
    this.showBottomBar = true, // กำหนดค่าเริ่มต้นเป็น true (แสดงเสมอหากไม่ได้ระบุเป็นอย่างอื่น)
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  int _currentIndex = -1; // กำหนด Index ให้ตรงกับเมนู Profile ของคุณใน BottomNavBar
  
  bool _isEditing = false;
  bool _isLoading = true;
  bool _isSaving = false;

  late TextEditingController _nameController;
  late TextEditingController _emailController;

  File? _newProfileImage;
  String? _existingImageUrl;
  String _displayName = "";
  String _email = "";

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController(); // อีเมลมักจะไม่ให้แก้ตรงๆ แต่ใส่ไว้แสดงผล
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // 🟢 ดึงข้อมูล User จาก Firestore
  Future<void> _loadUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          setState(() {
            _displayName = data['displayName'] ?? 'ไม่ระบุชื่อ';
            _email = data['email'] ?? user.email ?? 'ไม่ระบุอีเมล';
            _existingImageUrl = data['profileImageUrl'];
            
            _nameController.text = _displayName;
            _emailController.text = _email;
            
            _isLoading = false;
          });
        } else {
          setState(() {
            _displayName = user.displayName ?? 'ไม่ระบุชื่อ';
            _email = user.email ?? 'ไม่ระบุอีเมล';
            _existingImageUrl = user.photoURL;
            _nameController.text = _displayName;
            _emailController.text = _email;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
      setState(() => _isLoading = false);
    }
  }

  // 🟢 เลือกรูปโปรไฟล์ใหม่
  Future<void> _pickProfileImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        _newProfileImage = File(pickedFile.path);
      });
    }
  }

  // 🟢 บันทึกข้อมูล
  Future<void> _saveChanges() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณากรอกชื่อผู้ใช้งาน")),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String finalImageUrl = _existingImageUrl ?? "";

      // ถ้ามีการเปลี่ยนรูป
      if (_newProfileImage != null) {
        String fileName = 'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference ref = FirebaseStorage.instance.ref().child('user_profiles/$fileName');
        await ref.putFile(_newProfileImage!);
        finalImageUrl = await ref.getDownloadURL();
      }

      // อัปเดตข้อมูลใน Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'displayName': _nameController.text.trim(),
        'profileImageUrl': finalImageUrl,
        'email': _email, 
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // อัปเดต Profile ใน Firebase Auth (เผื่อไว้)
      await user.updateDisplayName(_nameController.text.trim());
      if (_newProfileImage != null) {
        await user.updatePhotoURL(finalImageUrl);
      }

      // อัปเดต UI กลับไปโหมดดูข้อมูล
      setState(() {
        _displayName = _nameController.text.trim();
        _existingImageUrl = finalImageUrl;
        _isEditing = false;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("บันทึกข้อมูลสำเร็จ")),
        );
      }
    } catch (e) {
      debugPrint("Save error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("เกิดข้อผิดพลาด: $e")),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  // 🟢 ยกเลิกการแก้ไข
  void _cancelEditing() {
    setState(() {
      _nameController.text = _displayName;
      _newProfileImage = null; 
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF90C2D8);
    const Color bgBlue = Color(0xFFE6F3FB);
    const Color yellowBtn = Color(0xFFFFEFA6);

    return Scaffold(
      // 🟢 2. เช็คเงื่อนไขก่อนแสดงผล BottomNavBar
      bottomNavigationBar: widget.showBottomBar
          ? CustomBottomNavBar(
              selectedIndex: _currentIndex,
              onItemTapped: (index) {
                setState(() => _currentIndex = index);
              },
            )
          : null, // ถ้า showBottomBar เป็น false จะคืนค่า null ทำให้ไม่แสดงบาร์
      body: SafeArea(
        child: Column(
          children: [
            HomeTopBar(
  showProfile: false, 
  onMenuTap: () {
    // เปลี่ยนจาก Navigator.pop เป็นการระบุหน้าใหม่
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const DogListPage()), // เปลี่ยน HomeScreen เป็นชื่อหน้าของคุณ
    );
  }, 
),
            
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // 🟢 ส่วนรูปโปรไฟล์และปุ่มแก้ไข
                            Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.grey[200],
                                  backgroundImage: _newProfileImage != null
                                      ? FileImage(_newProfileImage!) as ImageProvider
                                      : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                                          ? NetworkImage(_existingImageUrl!)
                                          : null,
                                  child: (_newProfileImage == null && 
                                          (_existingImageUrl == null || _existingImageUrl!.isEmpty))
                                      ? const Icon(Icons.person, size: 60, color: Colors.grey)
                                      : null,
                                ),
                                
                                GestureDetector(
                                  onTap: () {
                                    if (!_isEditing) {
                                      setState(() => _isEditing = true);
                                    } else {
                                      _pickProfileImage();
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: primaryBlue,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: Icon(
                                      _isEditing ? Icons.camera_alt : Icons.edit,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),

                            // 🟢 ส่วนแสดง/แก้ไขข้อมูล
                            _buildInfoSection(),

                            const SizedBox(height: 40),

                            // 🟢 ส่วนปุ่มกด (แสดงเฉพาะตอน Edit)
                            if (_isEditing)
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _isSaving ? null : _cancelEditing,
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        side: const BorderSide(color: Colors.grey),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                        "ยกเลิก",
                                        style: GoogleFonts.inter(
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _isSaving ? null : _saveChanges,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: yellowBtn,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: _isSaving
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.black54,
                                              ),
                                            )
                                          : Text(
                                              "บันทึก",
                                              style: GoogleFonts.inter(
                                                color: Colors.black87,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                              
                            // 🟢 ปุ่มออกจากระบบแบบสมบูรณ์
                            if (!_isEditing)
                              SizedBox(
                                width: double.infinity,
                                child: TextButton.icon(
                                  onPressed: () async {
                                    await FirebaseAuth.instance.signOut();
                                    if (!context.mounted) return;
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder: (context) => const LoginScreen(),
                                      ),
                                      (Route<dynamic> route) => false,
                                    );
                                  },
                                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                                  label: Text(
                                    "ออกจากระบบ",
                                    style: GoogleFonts.inter(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      children: [
        _buildRowItem("ชื่อผู้ใช้:", _nameController, isEditable: _isEditing),
        const Divider(height: 30, color: Color(0xFFEEEEEE)),
        _buildRowItem("อีเมล:", _emailController, isEditable: false),
      ],
    );
  }

  Widget _buildRowItem(String label, TextEditingController controller, {required bool isEditable}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: const Color(0xFF6A97A8),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: isEditable
              ? TextField(
                  controller: controller,
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                )
              : Text(
                  controller.text.isEmpty ? "-" : controller.text,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
      ],
    );
  }
}