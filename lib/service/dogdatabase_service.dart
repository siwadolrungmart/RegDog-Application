import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart'; 

class DatabaseService {
  final CollectionReference _dogCollection =
      FirebaseFirestore.instance.collection('dogs');

  // ==========================================
  // 1. CREATE: ฟังก์ชันสำหรับเพิ่มข้อมูลสุนัขตัวใหม่
  // ==========================================
  Future<bool> addDog({
    required String name,
    required String breed,
    required DateTime birthDate,
    required String gender,
    double weight = 0.0,
    String photoUrl = '',
    String? qrCodeId, 
    String microchip = '',
    String pedigree = '',
    String diseases = '',
  }) async {
    try {
      // ดึงข้อมูล User ที่กำลังล็อกอินอยู่ ณ ปัจจุบัน
      final user = FirebaseAuth.instance.currentUser;
      
      if (user == null) {
        debugPrint('❌ ไม่พบผู้ใช้งานในระบบ (อาจจะล็อกเอาท์ไปแล้ว)');
        return false;
      }
      
      final String currentUserId = user.uid; 

      // ถ้าไม่ได้ส่งรหัส QR มา ให้สร้างอัตโนมัติจากเวลา
      final String generateQrCode = qrCodeId ?? 'QR_${DateTime.now().millisecondsSinceEpoch}';
      
      // บันทึกลง Firestore
      final newDogRef = await _dogCollection.add({
        'ownerId': currentUserId, 
        'name': name,
        'breed': breed,
        'birthDate': Timestamp.fromDate(birthDate),
        'gender': gender,
        'weight': weight,
        'photoUrl': photoUrl,
        'qrCodeId': generateQrCode,
        'microchip': microchip,
        'pedigree': pedigree,
        'diseases': diseases,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ บันทึกข้อมูลน้องหมาสำเร็จ: $name (ของ User ID: $currentUserId)');

      // 🟢 ถ้ามีการใส่น้ำหนักเริ่มต้นมาด้วย ให้บันทึกเป็นประวัติครั้งแรกเลย
      if (weight > 0) {
        await recordWeightHistory(newDogRef.id, weight);
      }

      return true;
    } catch (e) {
      debugPrint('❌ เกิดข้อผิดพลาดในการบันทึกข้อมูล: $e');
      return false;
    }
  }

  // ==========================================
  // 2. READ: ฟังก์ชันดึงข้อมูลมาแสดงผล
  // ==========================================
  Stream<QuerySnapshot> getDogsByOwner(String ownerId) {
    return _dogCollection
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<DocumentSnapshot> getDogById(String docId) async {
    return await _dogCollection.doc(docId).get();
  }

  // ==========================================
  // 3. UPDATE: ฟังก์ชันแก้ไขข้อมูลสุนัข
  // ==========================================
  Future<bool> updateDog({
    required String docId,
    String? name,
    String? breed,
    DateTime? birthDate,
    String? gender,
    double? weight,
    String? photoUrl,
    String? qrCodeId,
    String? microchip,
    String? pedigree,
    String? diseases,
  }) async {
    try {
      Map<String, dynamic> updateData = {};
      if (name != null) updateData['name'] = name;
      if (breed != null) updateData['breed'] = breed;
      if (birthDate != null) updateData['birthDate'] = Timestamp.fromDate(birthDate);
      if (gender != null) updateData['gender'] = gender;
      if (weight != null) updateData['weight'] = weight;
      if (photoUrl != null) updateData['photoUrl'] = photoUrl;
      if (qrCodeId != null) updateData['qrCodeId'] = qrCodeId;
      if (microchip != null) updateData['microchip'] = microchip;
      if (pedigree != null) updateData['pedigree'] = pedigree;
      if (diseases != null) updateData['diseases'] = diseases;
      
      updateData['updatedAt'] = FieldValue.serverTimestamp();
      
      await _dogCollection.doc(docId).update(updateData);
      debugPrint('✅ แก้ไขข้อมูลน้องหมาสำเร็จ (ID: $docId)');
      return true;
    } catch (e) {
      debugPrint('❌ เกิดข้อผิดพลาดในการแก้ไขข้อมูล: $e');
      return false;
    }
  }

  // ==========================================
  // 4. DELETE: ฟังก์ชันลบข้อมูลสุนัข
  // ==========================================
  Future<bool> deleteDog(String docId) async {
    try {
      await _dogCollection.doc(docId).delete();
      debugPrint('✅ ลบข้อมูลน้องหมาสำเร็จ (ID: $docId)');
      return true;
    } catch (e) {
      debugPrint('❌ เกิดข้อผิดพลาดในการลบข้อมูล: $e');
      return false;
    }
  }

  // ==========================================
  // 5. WEIGHT HISTORY: ระบบประวัติน้ำหนัก (Subcollection)
  // ==========================================
  
  // 5.1 บันทึกประวัติน้ำหนัก
  Future<bool> recordWeightHistory(String dogId, double weight) async {
    try {
      await _dogCollection.doc(dogId).collection('weight_history').add({
        'weight': weight,
        'recordedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ บันทึกประวัติน้ำหนักสำเร็จ (น้ำหนัก: $weight กก.)');
      return true;
    } catch (e) {
      debugPrint('❌ เกิดข้อผิดพลาดในการบันทึกประวัติน้ำหนัก: $e');
      return false;
    }
  }

  // 5.2 ดึงประวัติน้ำหนักมาแสดงผล (เรียงจากล่าสุดไปเก่าสุด)
  Stream<QuerySnapshot> getWeightHistory(String dogId) {
    return _dogCollection
        .doc(dogId)
        .collection('weight_history')
        .orderBy('recordedAt', descending: true)
        .snapshots();
  }
}