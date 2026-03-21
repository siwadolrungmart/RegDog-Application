import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http; 
import 'dart:convert'; 

import 'package:regdogapp/component/upperbar.dart';
import 'package:regdogapp/component/bar.dart';
import 'package:regdogapp/component/map_view.dart';
import 'package:regdogapp/screen/dog_list.dart';

class PlacePage extends StatefulWidget {
  const PlacePage({super.key});

  @override
  State<PlacePage> createState() => _PlacePageState();
}

class _PlacePageState extends State<PlacePage> {
  int _currentIndex = 3; 
  Set<Marker> _markers = {};
  List<Map<String, dynamic>> _places = []; 
  bool _isLoading = true; 

  // 🔴 1. เอา API Key อันใหม่ของคุณ มาใส่ตรงนี้นะครับ 🔴
  final String googleApiKey = "AIzaSyC2ZsplIdFTiU5yK9oyq5N1Nu-s72_tWM4"; 

  @override
  void initState() {
    super.initState();
    _fetchRealPlaces(); 
  }

  // ✅ เปลี่ยนมาใช้ Places API (New) เรียบร้อยแล้ว
  Future<void> _fetchRealPlaces() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      double lat = position.latitude;
      double lng = position.longitude;

      final String url = 'https://places.googleapis.com/v1/places:searchNearby';

      // สร้าง Body สำหรับเวอร์ชันใหม่ หาคลินิกและร้านสัตว์เลี้ยง รัศมี 5 กม.
      final Map<String, dynamic> requestBody = {
        "includedTypes": ["pet_store", "veterinary_care"], 
        "maxResultCount": 20, 
        "locationRestriction": {
          "circle": {
            "center": {
              "latitude": lat,
              "longitude": lng
            },
            "radius": 5000.0 
          }
        },
        "languageCode": "th"
      };

      // กำหนด Header (สำคัญมากสำหรับเวอร์ชันใหม่)
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': googleApiKey,
        'X-Goog-FieldMask': 'places.id,places.displayName,places.formattedAddress,places.location,places.regularOpeningHours,places.photos', 
      };

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(requestBody),
      );

      debugPrint("===== NEW PLACES API RESPONSE =====");
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint(response.body); 
      debugPrint("===================================");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['places'] ?? []; // เวอร์ชันใหม่คีย์คือ 'places'

        List<Map<String, dynamic>> fetchedPlaces = [];
        Set<Marker> fetchedMarkers = {};

        for (var place in results) {
          final double placeLat = place['location']?['latitude'] ?? 0.0;
          final double placeLng = place['location']?['longitude'] ?? 0.0;
          final String name = place['displayName']?['text'] ?? 'ไม่มีชื่อ';
          final String address = place['formattedAddress'] ?? 'ไม่มีข้อมูลที่อยู่';
          final String placeId = place['id'] ?? '';

          String openStatus = "-";
          if (place['regularOpeningHours'] != null) {
            openStatus = (place['regularOpeningHours']['openNow'] == true) 
                ? "🟢 เปิดอยู่" 
                : "🔴 ปิดแล้ว";
          }

          String imageUrl = "https://images.unsplash.com/photo-1541599540903-216a46ca1dc0?q=80&w=500&auto=format&fit=crop";
          if (place['photos'] != null && place['photos'].isNotEmpty) {
            String photoName = place['photos'][0]['name']; 
            imageUrl = 'https://places.googleapis.com/v1/$photoName/media?maxHeightPx=400&maxWidthPx=400&key=$googleApiKey';
          }

          double distanceInMeters = Geolocator.distanceBetween(lat, lng, placeLat, placeLng);
          String distanceText = "${(distanceInMeters / 1000).toStringAsFixed(1)} กม.";

          fetchedPlaces.add({
            "name": name,
            "distance": distanceText,
            "location": address,
            "phone": "ดูในแอปแผนที่", 
            "time": openStatus,
            "image": imageUrl,
            "lat": placeLat,
            "lng": placeLng,
          });

          if (placeId.isNotEmpty) {
            fetchedMarkers.add(
              Marker(
                markerId: MarkerId(placeId),
                position: LatLng(placeLat, placeLng),
                infoWindow: InfoWindow(title: name, snippet: address),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              ),
            );
          }
        }

        setState(() {
          _places = fetchedPlaces;
          _markers = fetchedMarkers;
          _isLoading = false;
        });

      } else {
        debugPrint("Error fetching places: ${response.statusCode}");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _currentIndex,
        onItemTapped: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              HomeTopBar(
                showProfile: true,
                onMenuTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DogListPage()),
                  );
                },
                onNotificationTap: () => debugPrint("Notification tapped"),
                onProfileTap: () => debugPrint("Profile tapped"),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomMapView(markers: _markers),
                    
                    const SizedBox(height: 20),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal, 
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          SizedBox(width: 105, child: PlaceCategoryButton(icon: Icons.bathtub_outlined, label: "อาบน้ำ-ตัดขน", onTap: () {})),
                          const SizedBox(width: 12),
                          SizedBox(width: 105, child: PlaceCategoryButton(icon: Icons.local_cafe_outlined, label: "คาเฟ่-ร้านอาหาร", onTap: () {})),
                          const SizedBox(width: 12),
                          SizedBox(width: 105, child: PlaceCategoryButton(icon: Icons.local_hospital_outlined, label: "โรงพยาบาลสัตว์", onTap: () {})),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    _isLoading 
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF6A97A8)))
                      : _places.isEmpty 
                          ? const Center(child: Text("ไม่พบสถานที่ใกล้เคียง"))
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.70, 
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: _places.length,
                              itemBuilder: (context, index) {
                                final data = _places[index];
                                return PlaceCard(
                                  imageUrl: data['image'],
                                  name: data['name'],
                                  distance: data['distance'],
                                  location: data['location'],
                                  phone: data['phone'],
                                  time: data['time'],
                                );
                              },
                            ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// 2. Component: ปุ่มหมวดหมู่ (PlaceCategoryButton)
// ----------------------------------------------------------------------
class PlaceCategoryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const PlaceCategoryButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110, 
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFCDE8F5), 
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28,
                color: const Color(0xFF6A97A8), 
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11, 
                fontWeight: FontWeight.w600,
                color: Color(0xFF6A97A8),
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2, 
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// 3. Component: การ์ดแสดงสถานที่ (PlaceCard)
// ----------------------------------------------------------------------
class PlaceCard extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String distance;
  final String location;
  final String phone;
  final String time;

  const PlaceCard({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.distance,
    required this.location,
    required this.phone,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
            child: Image.network(
              imageUrl,
              height: 110, 
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6A97A8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        distance,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 8, thickness: 0.5),
                  _buildDetailRow(Icons.location_on_outlined, location),
                  _buildDetailRow(Icons.phone_outlined, phone),
                  _buildDetailRow(Icons.access_time_outlined, time),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}