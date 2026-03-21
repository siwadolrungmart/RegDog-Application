import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

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
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    } 

    Position position = await Geolocator.getCurrentPosition();
    
    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15.0,
          ),
        ),
      );
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
          markers: widget.markers, // ✅ ใช้ markers ที่ส่งมาจากหน้าหลัก
          onMapCreated: (GoogleMapController controller) {
            mapController = controller;
          },
          myLocationEnabled: true, 
          myLocationButtonEnabled: true, 
          zoomControlsEnabled: false,
        ),
      ),
    );
  }
}