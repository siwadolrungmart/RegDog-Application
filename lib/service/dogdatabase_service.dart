


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart'; 

class DatabaseService {
  final CollectionReference _dogCollection = FirebaseFirestore.instance.collection('dogs');

  // 1. CREATE: เพิ่มข้อมูลสุนัขตัวใหม่
  Future<bool> addDog({
    required String name, required String breed, required DateTime birthDate,
    required String gender, double weight = 0.0, String photoUrl = '',
    String? qrCodeId, String microchip = '', String pedigree = '', String diseases = '',
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      
      final String generateQrCode = qrCodeId ?? 'QR_${DateTime.now().millisecondsSinceEpoch}';
      final newDogRef = await _dogCollection.add({
        'ownerId': user.uid, 'name': name, 'breed': breed,
        'birthDate': Timestamp.fromDate(birthDate), 'gender': gender,
        'weight': weight, 'photoUrl': photoUrl, 'qrCodeId': generateQrCode,
        'microchip': microchip, 'pedigree': pedigree, 'diseases': diseases,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (weight > 0) await recordWeightHistory(newDogRef.id, weight);
      return true;
    } catch (e) {
      debugPrint('❌ Error adding dog: $e');
      return false;
    }
  }

  // 2. READ: ดึงข้อมูล
  Stream<QuerySnapshot> getDogsByOwner(String ownerId) {
    return _dogCollection.where('ownerId', isEqualTo: ownerId).orderBy('createdAt', descending: true).snapshots();
  }
  Future<DocumentSnapshot> getDogById(String docId) async {
    return await _dogCollection.doc(docId).get();
  }

  // 3. UPDATE: แก้ไขข้อมูลสุนัข
  Future<bool> updateDog({
    required String docId, String? name, String? breed, DateTime? birthDate,
    String? gender, double? weight, String? photoUrl, String? qrCodeId,
    String? microchip, String? pedigree, String? diseases,
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
      return true;
    } catch (e) {
      return false;
    }
  }

  // 4. DELETE: ลบข้อมูลสุนัข
  Future<bool> deleteDog(String docId) async {
    try {
      await _dogCollection.doc(docId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  // 5. WEIGHT HISTORY: ประวัติน้ำหนัก
  Future<bool> recordWeightHistory(String dogId, double weight) async {
    try {
      await _dogCollection.doc(dogId).collection('weight_history').add({
        'weight': weight, 'recordedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }
  Stream<QuerySnapshot> getWeightHistory(String dogId) {
    return _dogCollection.doc(dogId).collection('weight_history').orderBy('recordedAt', descending: true).snapshots();
  }

// ==========================================
  // 🟢 6. QR CODE TRACKING (แก้ไขใหม่)
  // ==========================================
  
  // เพิ่ม parameter 'activeToken' เพื่อรับรหัสสุ่มจากหน้า UI มาบันทึก
  Future<bool> saveQrTrackingInfo({
    required String dogId, 
    required String ownerContactName,
    required String phone, 
    required String address,
    required String note, 
    required String dogStatus,
    required String activeToken, // 🔥 เพิ่มตัวนี้
  }) async {
    try {
      await _dogCollection.doc(dogId).set({
        'qrTrackingData': {
          'contactName': ownerContactName,
          'phone': phone,
          'address': address,
          'note': note,
          'status': dogStatus,
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        },
        'currentStatus': dogStatus, 
        'activeQrToken': activeToken, // ✅ บันทึก Token ใหม่ลงฐานข้อมูลเสมอ
        'isQrActive': true,           // ✅ เปิดสถานะว่าคิวอาร์พร้อมใช้งาน
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('❌ Error saving QR data: $e');
      return false;
    }
  }

  // แก้ให้รับ token เข้ามา เพื่อสร้าง Link ที่ถูกต้อง
  String generateQrWebLink(String dogId, String token) {
    // แก้ yourdomain.com เป็นลิงก์เว็บจริงของคุณ (ถ้ามี)
    return "https://senior-project-regdog.web.app/scan?dogId=$dogId&token=$token";
  }
}