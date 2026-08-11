import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../attendance/models/attendance_model.dart';

class RiwayatDetailPage extends StatelessWidget {
  final AttendanceModel record;
  const RiwayatDetailPage({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final dateText =
        DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(record.checkInTime.toLocal());
    final checkInTime = DateFormat('HH:mm').format(record.checkInTime.toLocal());
    final checkOutTime = record.checkOutTime != null
        ? DateFormat('HH:mm').format(record.checkOutTime!.toLocal())
        : null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Riwayat',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateText, style: TextStyle(color: Colors.grey.shade500)),
            const SizedBox(height: 16),

            // CHECK IN CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFEAFB),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.login_rounded,
                                color: Color(0xFF6D5BD0), size: 18),
                          ),
                          const SizedBox(width: 10),
                          const Text('Check In',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text(checkInTime,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 1.4,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            record.checkInPhoto,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: Colors.grey.shade200),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.camera_alt,
                                      color: Colors.white, size: 12),
                                  SizedBox(width: 4),
                                  Text('Verified',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 11)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _LocationInfo(
                    locationName: record.location?.name ?? '-',
                    distanceLabel:
                        'Jarak dari titik presensi: ${record.checkInDistance.toStringAsFixed(0)}m',
                    lat: record.checkInLat,
                    lng: record.checkInLng,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // CHECK OUT CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDECEC),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.logout_rounded,
                                color: Color(0xFFDC2626), size: 18),
                          ),
                          const SizedBox(width: 10),
                          const Text('Check Out',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text(
                        checkOutTime ?? '--:--',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                  if (checkOutTime != null) ...[
                    const SizedBox(height: 12),
                    _LocationInfo(
                      locationName: record.location?.name ?? '-',
                      distanceLabel:
                          'Jarak dari titik absensi: ${(record.checkOutDistance ?? 0).toStringAsFixed(0)}m',
                      lat: record.checkOutLat ?? 0,
                      lng: record.checkOutLng ?? 0,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationInfo extends StatelessWidget {
  final String locationName;
  final String distanceLabel;
  final double lat;
  final double lng;

  const _LocationInfo({
    required this.locationName,
    required this.distanceLabel,
    required this.lat,
    required this.lng,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Text(locationName, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Text(distanceLabel, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.my_location, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}