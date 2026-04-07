import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:regdogapp/component/place_detail.dart';
import 'dart:convert';
import 'dart:math' as math;

import 'package:regdogapp/component/upperbar.dart';
import 'package:regdogapp/component/bar.dart';
import 'package:regdogapp/component/map_view.dart';
import 'package:regdogapp/screen/dog_list.dart';
import 'package:regdogapp/screen/register_screen/profile_user_screen.dart';

// 🟢 อย่าลืมแก้ path ด้านล่างนี้ให้ชี้ไปที่ไฟล์ place_detail.dart ของคุณ


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
  bool _isHorizontalView = true;

  String _selectedCategory = "ทั้งหมด";
  final String googleApiKey = "AIzaSyC2ZsplIdFTiU5yK9oyq5N1Nu-s72_tWM4";

  @override
  void initState() {
    super.initState();
    _checkAndRequestLocation();
  }

  Future<void> _checkAndRequestLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint("❌ Location service ยังปิดอยู่");
      setState(() => _isLoading = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      debugPrint("❌ ผู้ใช้ปฏิเสธสิทธิ์ถาวร");
      setState(() => _isLoading = false);
      return;
    }

    _fetchRealPlaces(
      textQuery:
          "ร้านอาบน้ำตัดขนสุนัข OR ร้านกรูมมิ่ง OR pet grooming OR dog grooming OR คาเฟ่หมาเข้าได้ OR ร้านอาหารสัตว์เลี้ยง OR pet friendly cafe OR dog friendly restaurant OR โรงพยาบาลสัตว์ OR คลินิกรักษาสัตว์ OR สัตวแพทย์ OR animal hospital OR veterinary clinic OR สวนสุนัข OR สวนหมาเข้าได้ OR dog park OR pet friendly park OR ร้านสัตว์เลี้ยง OR ร้านอาหารสุนัข OR pet store OR pet supplies OR ห้างสรรพสินค้าหมาเข้าได้ OR ห้าง pet friendly OR pet friendly shopping mall",
    );
  }

 Future<void> _fetchRealPlaces({required String textQuery}) async {
    setState(() => _isLoading = true);

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      double lat = position.latitude;
      double lng = position.longitude;

      double radiusInMeters = 10000.0;
      double latOffset = radiusInMeters / 111320.0;
      double lngOffset = radiusInMeters / (111320.0 * math.cos(lat * math.pi / 180.0));

      final String url = 'https://places.googleapis.com/v1/places:searchText';

      final Map<String, dynamic> requestBody = {
        "textQuery": textQuery,
        "maxResultCount": 20,
        "locationRestriction": {
          "rectangle": {
            "low": {
              "latitude": lat - latOffset,
              "longitude": lng - lngOffset
            },
            "high": {
              "latitude": lat + latOffset,
              "longitude": lng + lngOffset
            }
          }
        },
        "languageCode": "th",
      };

      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': googleApiKey,
        'X-Goog-FieldMask':
            'places.id,places.displayName,places.formattedAddress,places.location,places.regularOpeningHours,places.photos,places.nationalPhoneNumber,places.types,places.rating,places.userRatingCount,places.websiteUri,places.editorialSummary',
      };

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['places'] ?? [];

        List<Map<String, dynamic>> fetchedPlaces = [];
        Set<Marker> fetchedMarkers = {};

        for (var place in results) {
          final double placeLat = place['location']?['latitude'] ?? 0.0;
          final double placeLng = place['location']?['longitude'] ?? 0.0;
          
          double distanceInMeters = Geolocator.distanceBetween(lat, lng, placeLat, placeLng);

          if (distanceInMeters > radiusInMeters) {
            continue; 
          }

          final String name = place['displayName']?['text']?.toString() ?? 'ไม่มีชื่อ';
          final String address = place['formattedAddress']?.toString() ?? 'ไม่มีข้อมูลที่อยู่';
          final String placeId = place['id']?.toString() ?? '';
          final String phone = place['nationalPhoneNumber']?.toString() ?? "ไม่มีข้อมูลเบอร์โทร";
          
          final double rating = (place['rating'] ?? 0.0).toDouble();
          
          final int reviewCount = place['userRatingCount'] ?? 0;
          final String website = place['websiteUri'] ?? '-';
          final String description = place['editorialSummary']?['text'] ?? 'ยังไม่มีคำบรรยายสำหรับสถานที่นี้';
          final List<dynamic> rawWeekdays = place['regularOpeningHours']?['weekdayDescriptions'] ?? [];
          final List<String> weekdays = rawWeekdays.map((e) => e.toString()).toList();

          final List<dynamic> types = place['types'] ?? [];
          String catLabel = "สถานที่สัตว์เลี้ยง";
          IconData catIcon = Icons.pets_outlined;

          // ... (เงื่อนไขดึง Category ยังคงเหมือนเดิม) ...
          if (types.contains('veterinary_care')) {
            catLabel = "โรงพยาบาลสัตว์";
            catIcon = Icons.local_hospital_outlined;
          } else if (types.contains('pet_store')) {
            if (name.contains('อาบน้ำ') || name.contains('กรูมมิ่ง') || name.toLowerCase().contains('grooming')) {
              catLabel = "อาบน้ำ-ตัดขน";
              catIcon = Icons.bathtub_outlined;
            } else {
              catLabel = "ร้านขายของสัตว์";
              catIcon = Icons.pets_outlined;
            }
          } else if (types.contains('park') || types.contains('dog_park')) {
            catLabel = "สวนสาธารณะ";
            catIcon = Icons.park_outlined;
          } else if (types.contains('cafe') || types.contains('restaurant')) {
            catLabel = "คาเฟ่-ร้านอาหาร";
            catIcon = Icons.local_cafe_outlined;
          } else if (types.contains('shopping_mall')) {
            catLabel = "ห้างสรรพสินค้า";
            catIcon = Icons.store_mall_directory_outlined;
          } else {
            if (_selectedCategory != "ทั้งหมด") {
              catLabel = _selectedCategory;
              if (catLabel == "อาบน้ำ-ตัดขน") catIcon = Icons.bathtub_outlined;
              else if (catLabel == "คาเฟ่-ร้านอาหาร") catIcon = Icons.local_cafe_outlined;
              else if (catLabel == "โรงพยาบาลสัตว์") catIcon = Icons.local_hospital_outlined;
              else if (catLabel == "สวนสาธารณะ") catIcon = Icons.park_outlined;
              else if (catLabel == "ร้านขายของสัตว์") catIcon = Icons.pets_outlined;
              else if (catLabel == "ห้างสรรพสินค้า") catIcon = Icons.store_mall_directory_outlined;
            }
          }

          String openStatus = "ไม่มีข้อมูลเวลาเปิด-ปิด";
          if (place['regularOpeningHours'] != null) {
            bool isOpen = place['regularOpeningHours']['openNow'] == true;
            String statusIcon = isOpen ? "🟢" : "🔴";

            if (place['regularOpeningHours']['weekdayDescriptions'] != null) {
              try {
                int weekday = DateTime.now().weekday;
                var rawDesc = place['regularOpeningHours']['weekdayDescriptions'][weekday - 1];
                String todayDesc = rawDesc?.toString() ?? "";
                
                String timePart = todayDesc.contains(':')
                    ? todayDesc.substring(todayDesc.indexOf(':') + 1).trim()
                    : todayDesc;
                openStatus = "$statusIcon $timePart";
              } catch (e) {
                openStatus = "$statusIcon ${isOpen ? 'เปิดอยู่' : 'ปิดแล้ว'}";
              }
            } else {
              openStatus = "$statusIcon ${isOpen ? 'เปิดอยู่' : 'ปิดแล้ว'}";
            }
          }

          // 🟢 1. ส่วนที่แก้ไข: สร้างตัวแปร List สำหรับเก็บรูปทั้งหมด
          List<String> allImageUrls = [];
          String singleImageUrl = "https://images.unsplash.com/photo-1541599540903-216a46ca1dc0?q=80&w=500&auto=format&fit=crop";
          
          if (place['photos'] != null && place['photos'].isNotEmpty) {
            // วนลูปดึงรูปทั้งหมดที่ API ส่งมา (จำกัดแค่ 5 รูปก็พอครับ จะได้ไม่กินเน็ตเยอะ)
            int photoCount = place['photos'].length > 5 ? 5 : place['photos'].length;
            for (int i = 0; i < photoCount; i++) {
              String photoName = place['photos'][i]['name']?.toString() ?? '';
              if (photoName.isNotEmpty) {
                allImageUrls.add('https://places.googleapis.com/v1/$photoName/media?maxHeightPx=400&maxWidthPx=400&key=$googleApiKey');
              }
            }
            
            // ตั้งให้รูปแรกเป็นหน้าปก (ไว้แสดงในการ์ดหน้าแรก)
            if (allImageUrls.isNotEmpty) {
               singleImageUrl = allImageUrls[0];
            }
          }

          String distanceText = "${(distanceInMeters / 1000).toStringAsFixed(1)} กม.";

          fetchedPlaces.add({
            "name": name,
            "distance": distanceText,
            "location": address,
            "phone": phone,
            "time": openStatus,
            "image": singleImageUrl, // ส่งรูปเดียวให้หน้าแรกใช้เป็นปก
            "images": allImageUrls, // 🟢 2. เพิ่ม key ใหม่ ส่ง Array ของรูปทั้งหมดให้หน้า Detail
            "lat": placeLat,
            "lng": placeLng,
            "rawDistance": distanceInMeters,
            "categoryLabel": catLabel,
            "categoryIcon": catIcon,
            "rating": rating,
            "reviewCount": reviewCount,
            "website": website,
            "description": description,
            "weekdays": weekdays,
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

        fetchedPlaces.sort((a, b) => (a['rawDistance'] as double).compareTo(b['rawDistance'] as double));

        setState(() {
          _places = fetchedPlaces;
          _markers = fetchedMarkers;
          _isLoading = false;
        });
      } else {
        debugPrint("API Error: ${response.statusCode}");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Exception: $e");
      setState(() => _isLoading = false);
    }
  }

  void _onCategoryTapped(String categoryName, String query) {
    if (_selectedCategory == categoryName) return;
    setState(() => _selectedCategory = categoryName);
    _fetchRealPlaces(textQuery: query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _currentIndex,
        onItemTapped: (index) => setState(() => _currentIndex = index),
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
  
      onProfileTap: () {
        // 🟢 เปลี่ยนเส้นทางไปหน้า User Profile
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UserProfileScreen()),
        );
      },
    ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(left: 0, right: 0, bottom: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 280,
                      child: CustomMapView(markers: _markers),
                    ),
                    const SizedBox(height: 20),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          // ส่วนของปุ่มหมวดหมู่ ยังเหมือนเดิม
                          SizedBox(
                            width: 105,
                            child: PlaceCategoryButton(
                              icon: Icons.apps_outlined,
                              label: "ทั้งหมด",
                              isSelected: _selectedCategory == "ทั้งหมด",
                              onTap: () => _onCategoryTapped("ทั้งหมด", "ร้านอาบน้ำตัดขนสุนัข OR ร้านกรูมมิ่ง OR pet grooming OR dog grooming OR คาเฟ่หมาเข้าได้ OR ร้านอาหารสัตว์เลี้ยง OR pet friendly cafe OR dog friendly restaurant OR โรงพยาบาลสัตว์ OR คลินิกรักษาสัตว์ OR สัตวแพทย์ OR animal hospital OR veterinary clinic OR สวนสุนัข OR สวนหมาเข้าได้ OR dog park OR pet friendly park OR ร้านสัตว์เลี้ยง OR ร้านอาหารสุนัข OR pet store OR pet supplies OR ห้างสรรพสินค้าหมาเข้าได้ OR ห้าง pet friendly OR pet friendly shopping mall"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 105,
                            child: PlaceCategoryButton(
                              icon: Icons.bathtub_outlined,
                              label: "อาบน้ำ-ตัดขน",
                              isSelected: _selectedCategory == "อาบน้ำ-ตัดขน",
                              onTap: () => _onCategoryTapped("อาบน้ำ-ตัดขน", "ร้านอาบน้ำตัดขนสุนัข OR ร้านกรูมมิ่ง OR pet grooming OR dog grooming"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 105,
                            child: PlaceCategoryButton(
                              icon: Icons.local_cafe_outlined,
                              label: "คาเฟ่-ร้านอาหาร",
                              isSelected: _selectedCategory == "คาเฟ่-ร้านอาหาร",
                              onTap: () => _onCategoryTapped("คาเฟ่-ร้านอาหาร", "คาเฟ่หมาเข้าได้ OR ร้านอาหารสัตว์เลี้ยง OR pet friendly cafe OR dog friendly restaurant"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 105,
                            child: PlaceCategoryButton(
                              icon: Icons.local_hospital_outlined,
                              label: "โรงพยาบาลสัตว์",
                              isSelected: _selectedCategory == "โรงพยาบาลสัตว์",
                              onTap: () => _onCategoryTapped("โรงพยาบาลสัตว์", "โรงพยาบาลสัตว์ OR คลินิกรักษาสัตว์ OR สัตวแพทย์ OR animal hospital OR veterinary clinic"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 105,
                            child: PlaceCategoryButton(
                              icon: Icons.park_outlined,
                              label: "สวนสาธารณะ",
                              isSelected: _selectedCategory == "สวนสาธารณะ",
                              onTap: () => _onCategoryTapped("สวนสาธารณะ", "สวนสุนัข OR สวนหมาเข้าได้ OR dog park OR pet friendly park"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 105,
                            child: PlaceCategoryButton(
                              icon: Icons.pets_outlined,
                              label: "ร้านขายของสัตว์",
                              isSelected: _selectedCategory == "ร้านขายของสัตว์",
                              onTap: () => _onCategoryTapped("ร้านขายของสัตว์", "ร้านสัตว์เลี้ยง OR ร้านอาหารสุนัข OR pet store OR pet supplies"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 105,
                            child: PlaceCategoryButton(
                              icon: Icons.store_mall_directory_outlined,
                              label: "ห้างสรรพสินค้า",
                              isSelected: _selectedCategory == "ห้างสรรพสินค้า",
                              onTap: () => _onCategoryTapped("ห้างสรรพสินค้า", "ห้างสรรพสินค้าหมาเข้าได้ OR ห้าง pet friendly OR pet friendly shopping mall"),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "สถานที่ใกล้เคียง",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6A97A8),
                          ),
                        ),
                        Container(
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => setState(() => _isHorizontalView = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _isHorizontalView ? const Color(0xFF6A97A8) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(
                                    Icons.view_carousel_outlined,
                                    size: 18,
                                    color: _isHorizontalView ? Colors.white : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _isHorizontalView = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: !_isHorizontalView ? const Color(0xFF6A97A8) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Icon(
                                    Icons.grid_view_outlined,
                                    size: 18,
                                    color: !_isHorizontalView ? Colors.white : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(color: Color(0xFF6A97A8)),
                            ),
                          )
                        : _places.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text("ไม่พบสถานที่ใกล้เคียง", style: TextStyle(color: Colors.grey)),
                            ),
                          )
                        : _isHorizontalView
                        ? SizedBox(
                            height: 275,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: _places.length,
                              itemBuilder: (context, index) {
                                final data = _places[index];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: SizedBox(
                                    width: 220,
                                    child: GestureDetector( // 🟢 ครอบตรงนี้
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PlaceDetailPage(placeData: data),
                                          ),
                                        );
                                      },
                                      child: PlaceCard(
                                        imageUrl: data['image']?.toString() ?? '',
                                        name: data['name']?.toString() ?? 'ไม่มีชื่อ',
                                        distance: data['distance']?.toString() ?? '',
                                        location: data['location']?.toString() ?? 'ไม่มีข้อมูลที่อยู่',
                                        phone: data['phone']?.toString() ?? 'ไม่มีข้อมูลเบอร์โทร',
                                        time: data['time']?.toString() ?? 'ไม่มีข้อมูลเวลาเปิด-ปิด',
                                        categoryLabel: data['categoryLabel']?.toString() ?? '',
                                        categoryIcon: data['categoryIcon'] ?? Icons.pets_outlined,
                                        rating: data['rating'] as double? ?? 0.0,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.62,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: _places.length,
                            itemBuilder: (context, index) {
                              final data = _places[index];
                              return GestureDetector( // 🟢 ครอบตรงนี้
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PlaceDetailPage(placeData: data),
                                    ),
                                  );
                                },
                                child: PlaceCard(
                                  imageUrl: data['image']?.toString() ?? '',
                                  name: data['name']?.toString() ?? 'ไม่มีชื่อ',
                                  distance: data['distance']?.toString() ?? '',
                                  location: data['location']?.toString() ?? 'ไม่มีข้อมูลที่อยู่',
                                  phone: data['phone']?.toString() ?? 'ไม่มีข้อมูลเบอร์โทร',
                                  time: data['time']?.toString() ?? 'ไม่มีข้อมูลเวลาเปิด-ปิด',
                                  categoryLabel: data['categoryLabel']?.toString() ?? '',
                                  categoryIcon: data['categoryIcon'] ?? Icons.pets_outlined,
                                  rating: data['rating'] as double? ?? 0.0,
                                ),
                              );
                            },
                          ),
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

// ... โค้ด Component PlaceCategoryButton และ PlaceCard ด้านล่างปล่อยไว้เหมือนเดิมได้เลย ...
// (ดึงมาจากโค้ดเก่าของคุณได้เลยครับ ผมตัดออกเพื่อประหยัดพื้นที่ให้คุณก๊อปง่ายๆ)

// ----------------------------------------------------------------------
// Component: ปุ่มหมวดหมู่ (PlaceCategoryButton)
// ----------------------------------------------------------------------
class PlaceCategoryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const PlaceCategoryButton({
    super.key,
    required this.icon,
    required this.label,
    this.isSelected = false,
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
          color: isSelected ? const Color(0xFF6A97A8) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: isSelected ? const Color(0xFF6A97A8) : Colors.grey.shade100,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.2) : const Color(0xFFCDE8F5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28,
                color: isSelected ? Colors.white : const Color(0xFF6A97A8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF6A97A8),
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
// Component: การ์ดแสดงสถานที่ (PlaceCard)
// ----------------------------------------------------------------------
class PlaceCard extends StatelessWidget {
  final String imageUrl;
  final String name;
  final String distance;
  final String location;
  final String phone;
  final String time;
  final String categoryLabel;
  final IconData categoryIcon;
  final double rating;

  const PlaceCard({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.distance,
    required this.location,
    required this.phone,
    required this.time,
    required this.categoryLabel,
    required this.categoryIcon,
    this.rating = 0.0,
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
              imageUrl.isNotEmpty 
                ? imageUrl 
                : 'https://images.unsplash.com/photo-1541599540903-216a46ca1dc0?q=80&w=500&auto=format&fit=crop',
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(categoryIcon, size: 14, color: const Color(0xFFF0A381)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                categoryLabel,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFF0A381),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (rating > 0)
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(
                              rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}