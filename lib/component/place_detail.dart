import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
// 🟢 1. Import 2 ตัวนี้เพิ่มสำหรับการจัดการนิ้วสัมผัส
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

class PlaceDetailPage extends StatefulWidget {
  final Map<String, dynamic> placeData;

  const PlaceDetailPage({super.key, required this.placeData});

  @override
  State<PlaceDetailPage> createState() => _PlaceDetailPageState();
}

class _PlaceDetailPageState extends State<PlaceDetailPage> {
  bool _isHoursExpanded = false;
  
  // สร้าง Controller สำหรับ PageView และตัวแปรเก็บหน้าปัจจุบัน
  final PageController _pageController = PageController();
  int _currentPage = 0;

  Future<void> _launchWebsite(String urlString) async {
    if (urlString == '-' || urlString.isEmpty) return;
    
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        debugPrint('Could not launch $urlString');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ดึงข้อมูลพื้นฐาน
    final double lat = widget.placeData['lat'] ?? 0.0;
    final double lng = widget.placeData['lng'] ?? 0.0;
    final String name = widget.placeData['name'] ?? 'ไม่มีชื่อ';
    final String distance = widget.placeData['distance'] ?? '';
    final String address = widget.placeData['location'] ?? '-';
    final String phone = widget.placeData['phone'] ?? '-';
    final String timeStatus = widget.placeData['time'] ?? '-';
    
    final double rating = (widget.placeData['rating'] ?? 0.0).toDouble(); 
    
    final String website = widget.placeData['website'] ?? '-';
    final int reviewCount = widget.placeData['reviewCount'] ?? 0;
    final String description = widget.placeData['description'] ?? 'ยังไม่มีคำบรรยายสำหรับสถานที่นี้';
    final List<String> weekdays = List<String>.from(widget.placeData['weekdays'] ?? []);

    // ดึง List ของรูปภาพมาใช้งาน
    List<String> imageUrls = [];
    if (widget.placeData['images'] != null && widget.placeData['images'] is List) {
      imageUrls = List<String>.from(widget.placeData['images']);
    } else if (widget.placeData['image'] != null && widget.placeData['image'].toString().isNotEmpty) {
      imageUrls = [widget.placeData['image']];
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. แผนที่ด้านบนสุด
              Container(
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
                  child: Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(lat, lng),
                          zoom: 15, 
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('detail_marker'),
                            position: LatLng(lat, lng),
                            infoWindow: InfoWindow(title: name), 
                          ),
                        },
                        myLocationEnabled: true,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        
                        // 🟢 2. เปิดการตั้งค่าให้ใช้นิ้วเลื่อนและซูมได้
                        zoomGesturesEnabled: true,
                        scrollGesturesEnabled: true,
                        
                        // 🟢 3. ใส่ EagerGestureRecognizer เพื่อดักจับนิ้วที่แตะบนแผนที่
                        gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                          Factory<OneSequenceGestureRecognizer>(
                            () => EagerGestureRecognizer(),
                          ),
                        },
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                )
                              ]
                            ),
                            child: const Icon(Icons.arrow_back, color: Colors.black87),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24), 

              // 2. ส่วนแสดงรูปภาพ (สไลด์ได้)
              imageUrls.isEmpty
                  ? const SizedBox.shrink()
                  : SizedBox(
                      height: 200,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: imageUrls.length,
                              onPageChanged: (int page) {
                                setState(() {
                                  _currentPage = page;
                                });
                              },
                              itemBuilder: (context, index) {
                                return Image.network(
                                  imageUrls[index],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: Colors.grey.shade300,
                                    child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                                  ),
                                );
                              },
                            ),
                          ),
                          // จุด Indicator (แสดงเมื่อมีมากกว่า 1 รูป)
                          if (imageUrls.length > 1)
                            Positioned(
                              bottom: 10,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(imageUrls.length, (index) {
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: _currentPage == index ? 10.0 : 8.0,
                                    height: _currentPage == index ? 10.0 : 8.0,
                                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _currentPage == index
                                          ? const Color(0xFF6A97A8) // สีเขียวอมฟ้า
                                          : Colors.white.withOpacity(0.7),
                                      boxShadow: const [
                                        BoxShadow(color: Colors.black26, blurRadius: 2)
                                      ],
                                    ),
                                  );
                                }),
                              ),
                            ),
                        ],
                      ),
                    ),

              // 3. กล่องรายละเอียดสีขาว
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.mitr(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6A97A8),
                            ),
                          ),
                        ),
                        Text(
                          distance,
                          style: GoogleFonts.mitr(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    _buildInfoRow(Icons.location_on_outlined, address),
                    const SizedBox(height: 10),

                    _buildInfoRow(Icons.phone_outlined, phone),
                    const SizedBox(height: 10),

                    InkWell(
                      onTap: () => setState(() => _isHoursExpanded = !_isHoursExpanded),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.access_time_outlined, size: 20, color: Color(0xFF9E9E9E)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      timeStatus.replaceAll('🟢 ', '').replaceAll('🔴 ', ''), 
                                      style: GoogleFonts.mitr(fontSize: 14, color: Colors.black87),
                                    ),
                                    Icon(
                                      _isHoursExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                      color: Colors.grey.shade600,
                                    ),
                                  ],
                                ),
                                if (_isHoursExpanded && weekdays.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  ...weekdays.map((day) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Text(
                                      day,
                                      style: GoogleFonts.mitr(fontSize: 13, color: Colors.grey.shade700),
                                    ),
                                  )).toList(),
                                ] else if (_isHoursExpanded && weekdays.isEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text("ไม่มีข้อมูลเวลาทำการรายวัน", style: GoogleFonts.mitr(fontSize: 13, color: Colors.grey.shade500)),
                                ]
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    _buildInfoRow(
                      Icons.language_outlined, 
                      website,
                      isLink: website != '-',
                      onTap: website != '-' ? () => _launchWebsite(website) : null,
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Icon(Icons.star_border_outlined, size: 20, color: Color(0xFF9E9E9E)),
                        const SizedBox(width: 10),
                        Text(
                          "${rating.toStringAsFixed(2)} ($reviewCount รีวิว)",
                          style: GoogleFonts.mitr(fontSize: 14, color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    Text(
                      "เกี่ยวกับเรา",
                      style: GoogleFonts.mitr(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6A97A8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: GoogleFonts.mitr(fontSize: 13, color: Colors.black54, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {bool isLink = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF9E9E9E)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.mitr(
                fontSize: 14,
                color: isLink ? Colors.blue : Colors.black87,
                decoration: isLink ? TextDecoration.underline : TextDecoration.none,
                decorationColor: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}