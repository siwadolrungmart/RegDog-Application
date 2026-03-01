import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  final CollectionReference _dogCollection = 
      FirebaseFirestore.instance.collection('dogs');

  // ==========================================
  // 1. CREATE: ฟังก์ชันสำหรับเพิ่มข้อมูลสุนัขตัวใหม่ (ใส่ Default ไว้ที่นี่)
  // ==========================================
  Future<bool> addDog({
    // --- ข้อมูลที่บังคับต้องส่งมาจากหน้า UI ---
    required String name,
    required String breed,
    required DateTime birthDate,
    required String gender,
    
    // --- ข้อมูลที่มีค่า Default ให้แล้ว (ฝั่ง UI ไม่ต้องส่งมาก็ได้) ---
    String ownerId = 'temp_user_123', 
    double weight = 0.0,
    String photoUrl = '',
    String? qrCodeId, // ปล่อยเป็น Nullable เดี๋ยวเราไปสร้างข้างใน
    
  }) async {
    try {
      // ถ้าไม่ได้ส่งรหัส QR มา ให้สร้างอัตโนมัติจากเวลา
      //final String generateQrCode = qrCodeId ?? 'QR_${DateTime.now().millisecondsSinceEpoch}';

      // นำข้อมูลทั้งหมด (ทั้งที่รับมาและ Default) บันทึกลง Firestore
      await _dogCollection.add({
        'ownerId': ownerId,
        'name': name,
        'breed': breed,
        'birthDate': Timestamp.fromDate(birthDate),
        'gender': gender,
        'weight': weight,
        'photoUrl': photoUrl,
        'qrCodeId': qrCodeId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ บันทึกข้อมูลน้องหมาสำเร็จ: $name');
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
}