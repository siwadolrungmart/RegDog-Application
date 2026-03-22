import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
// 🟢 1. Import 2 ตัวนี้เพิ่มเข้ามาสำหรับการจัดการนิ้วสัมผัส (Gestures)
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

class CustomMapView extends StatefulWidget {
  // รับข้อมูลหมุด (Markers) มาจากหน้าหลัก
  final Set<Marker> markers;

  const CustomMapView({
    super.key,
    required this.markers,
  });

  @override
  State<CustomMapView> createState() => _CustomMapViewState();
}

class _CustomMapViewState extends State<CustomMapView> {
  GoogleMapController? mapController;
  
  // ตำแหน่งเริ่มต้น (ตั้งไว้เผื่อกรณีผู้ใช้ไม่เปิด GPS)
  final LatLng _initialPosition = const LatLng(13.7649, 100.5383);

  @override
  void initState() {
    super.initState();
    _getUserLocation(); // เรียกฟังก์ชันหาพิกัดตอนเปิดแผนที่
  }

  // ฟังก์ชันสำหรับขออนุญาตและดึงพิกัดปัจจุบันของผู้ใช้
  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied.');
        return;
      } 

      Position position = await Geolocator.getCurrentPosition();
      
      if (mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 14.0, 
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 270, 
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _initialPosition,
            zoom: 14.0, 
          ),
          markers: widget.markers, 
          onMapCreated: (GoogleMapController controller) {
            mapController = controller;
          },
          myLocationEnabled: true, 
          myLocationButtonEnabled: true, 
          zoomControlsEnabled: false, // ซ่อนปุ่ม +/- บนหน้าจอ
          
          // 🟢 2. เปิดให้ใช้นิ้วซูมและเลื่อนได้
          zoomGesturesEnabled: true, 
          scrollGesturesEnabled: true,
          
          // 🟢 3. เพิ่ม gestureRecognizers เพื่อให้แผนที่ใช้งานได้แม้จะอยู่ในหน้าที่ไถขึ้นลงได้
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(
              () => EagerGestureRecognizer(),
            ),
          },
        ),
      ),
    );
  }
}