import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CurrentDogProvider extends ChangeNotifier {
  String? _currentDogId;
  Map<String, dynamic>? _currentDogData;

  String? get currentDogId => _currentDogId;
  Map<String, dynamic>? get currentDogData => _currentDogData;

  // ==================== GETTER ที่ใช้งานง่าย ====================
  String get dogName => _currentDogData?['name'] ?? 'ไม่ทราบชื่อ';
  String get dogBreed => _currentDogData?['breed'] ?? 'ไม่ทราบพันธุ์';
  String get dogImage => _currentDogData?['photoUrl'] ?? '';
  String get dogGender => _currentDogData?['gender'] ?? 'ไม่ระบุ';
  
  // ใช้ num? เพื่อป้องกัน error กรณีค่าใน Firestore เป็น int (เช่น 5 แทน 5.0)
  double get dogWeight => (_currentDogData?['weight'] as num?)?.toDouble() ?? 0.0;
  
  // แปลง Timestamp ของ Firestore ให้เป็นวันที่แบบอ่านง่าย
  String get dogBirthDate {
    if (_currentDogData?['birthDate'] is Timestamp) {
      final dt = (_currentDogData!['birthDate'] as Timestamp).toDate();
      // หากต้องการเปลี่ยนรูปแบบวันที่ สามารถแก้ตรง 'dd MMM yyyy' ได้เลย
      return DateFormat('dd MMM yyyy').format(dt); 
    }
    return _currentDogData?['birthDate']?.toString() ?? 'ไม่ทราบวันที่';
  }

  // คำนวณอายุอัตโนมัติจากวันเกิด
  String get dogAge {
    if (_currentDogData?['birthDate'] is Timestamp) {
      final birthDate = (_currentDogData!['birthDate'] as Timestamp).toDate();
      final now = DateTime.now();
      final diff = now.difference(birthDate);
      int totalMonths = (diff.inDays / 30.44).round();
      int years = totalMonths ~/ 12;
      int remainingMonths = totalMonths % 12;
      
      return years > 0 
          ? '$years ปี $remainingMonths เดือน' 
          : '$remainingMonths เดือน';
    }
    return 'ไม่ทราบอายุ';
  }

  String get dogMicrochip => _currentDogData?['microchip'] ?? '';
  String get dogPedigree => _currentDogData?['pedigree'] ?? '';
  String get dogDiseases => _currentDogData?['diseases'] ?? '';
  String? get dogQrCodeId => _currentDogData?['qrCodeId'] as String?;

  // ==================== QR TRACKING DATA ====================
  Map<String, dynamic>? get qrTrackingData => _currentDogData?['qrTrackingData'] as Map<String, dynamic>?;

  String get ownerContactName => qrTrackingData?['contactName'] ?? '';
  String get ownerPhone => qrTrackingData?['phone'] ?? '';
  String get ownerAddress => qrTrackingData?['address'] ?? '';
  String get ownerNote => qrTrackingData?['note'] ?? '';
  String get currentStatus => _currentDogData?['currentStatus'] ?? 'ไม่ระบุ';

  // ==================== METHODS ====================

  // ฟังก์ชันเลือกสุนัขแบบแนบข้อมูลมาเลย (แบบเก่า)
  void selectDog(String dogId, Map<String, dynamic> dogData) {
    _currentDogId = dogId;
    _currentDogData = dogData;
    notifyListeners();
  }

  // ฟังก์ชันใหม่: ให้ Provider ดึงข้อมูลจาก Firestore เองด้วย docId
  Future<void> selectDogById(String dogId) async {
    try {
      // หมายเหตุ: เช็คชื่อ Collection 'dogs' ให้ตรงกับใน Firestore ของคุณ
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('dogs').doc(dogId).get();
      
      if (doc.exists) {
        _currentDogId = doc.id;
        _currentDogData = doc.data() as Map<String, dynamic>;
        notifyListeners();
      } else {
        debugPrint("ไม่พบข้อมูลสุนัข ID: $dogId");
      }
    } catch (e) {
      debugPrint("เกิดข้อผิดพลาดในการดึงข้อมูลสุนัข: $e");
    }
  }

  void clearCurrentDog() {
    _currentDogId = null;
    _currentDogData = null;
    notifyListeners();
  }
}