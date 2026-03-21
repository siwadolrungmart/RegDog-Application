import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DogMapScreen extends StatefulWidget {
  const DogMapScreen({super.key});

  @override
  State<DogMapScreen> createState() => _DogMapScreenState();
}

class _DogMapScreenState extends State<DogMapScreen> {
  // ตั้งค่าจุดศูนย์กลางเริ่มต้น (เช่น อนุสาวรีย์ชัยฯ)
  final LatLng _center = const LatLng(13.7649, 100.5383);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สถานที่สำหรับน้องหมา', style: TextStyle(color: Colors.black)),
        backgroundColor: const Color(0xFF90C2D8),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _center,
          zoom: 14.0, // ยิ่งค่าน้อยยิ่งซูมออกเห็นกว้างๆ
        ),
      ),
    );
  }
}