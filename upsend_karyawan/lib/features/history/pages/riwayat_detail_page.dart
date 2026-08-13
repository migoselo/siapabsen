import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api.dart';
import '../../attendance/models/attendance_model.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RiwayatDetailPage extends StatelessWidget {
  final AttendanceModel record;
  const RiwayatDetailPage({super.key, required this.record});

  String _resolvePhotoUrl(String? photoPath) {
    final value = photoPath?.trim() ?? '';
    if (value.isEmpty) return '';

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    final normalized = value.startsWith('/') ? value.substring(1) : value;
    final baseUri = Uri.parse(Api.dio.options.baseUrl);
    final origin =
        '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}';

    if (normalized.startsWith('storage/')) {
      return '$origin/$normalized';
    }

    return '$origin/storage/$normalized';
  }

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat(
      'EEEE, d MMMM yyyy',
      'id_ID',
    ).format(record.checkInTime.toLocal());
    final checkInTime = DateFormat(
      'HH:mm',
    ).format(record.checkInTime.toLocal());
    final checkOutTime = record.checkOutTime != null
        ? DateFormat('HH:mm').format(record.checkOutTime!.toLocal())
        : null;
    final checkInPhotoUrl = _resolvePhotoUrl(record.checkInPhoto);
    final hasValidCheckInPhoto = checkInPhotoUrl.isNotEmpty;
    final checkOutPhotoUrl = _resolvePhotoUrl(record.checkOutPhoto);
    final hasValidCheckOutPhoto = checkOutPhotoUrl.isNotEmpty;

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
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateText,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),

            // CHECK IN CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFC6C5D0)),
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
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              shape: BoxShape.circle,
                            ),
                            child: SvgPicture.asset(
                              'assets/images/checkin.svg',
                              width: 22,
                              height: 22,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF1DB677), // hijau
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Check In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        checkInTime,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1DB677),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: hasValidCheckInPhoto
                        ? () => showDialog(
                            context: context,
                            builder: (_) => Dialog(
                              insetPadding: const EdgeInsets.all(16),
                              backgroundColor: Colors.black,
                              child: Stack(
                                children: [
                                  Center(
                                    child: InteractiveViewer(
                                      child: Image.network(
                                        checkInPhotoUrl,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: GestureDetector(
                                      onTap: () => Navigator.pop(context),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : null,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 1.4,
                        child: hasValidCheckInPhoto
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    checkInPhotoUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: const Color(0xFFF3F4F6),
                                      child: const Center(
                                        child: Icon(
                                          Icons.image_not_supported_outlined,
                                          color: Color(0xFF9CA3AF),
                                          size: 32,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.camera_alt,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Terverifikasi',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Container(
                                color: const Color(0xFFF3F4F6),
                                child: const Center(
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    color: Color(0xFF9CA3AF),
                                    size: 32,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _LocationInfo(
                    locationName: record.location?.name ?? '-',
                    distancePrefix: 'Jarak dari titik presensi: ',
                    distanceValue:
                        '${record.checkInDistance.toStringAsFixed(0)}m',
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
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFC6C5D0)),
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
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDBEAFE), // biru muda
                              shape: BoxShape.circle,
                            ),
                            child: SvgPicture.asset(
                              'assets/images/checkout.svg',
                              width: 22,
                              height: 22,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF2F3B69), // biru
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Check Out',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        checkOutTime ?? '--:--',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2F3B69),
                        ),
                      ),
                    ],
                  ),
                  if (checkOutTime != null || hasValidCheckOutPhoto) ...[
                    const SizedBox(height: 12),
                    if (hasValidCheckOutPhoto)
                      GestureDetector(
                        onTap: () => showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            insetPadding: const EdgeInsets.all(16),
                            backgroundColor: Colors.black,
                            child: Stack(
                              children: [
                                Center(
                                  child: InteractiveViewer(
                                    child: Image.network(
                                      checkOutPhotoUrl,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AspectRatio(
                            aspectRatio: 1.4,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  checkOutPhotoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: const Color(0xFFF3F4F6),
                                    child: const Center(
                                      child: Icon(
                                        Icons.image_not_supported_outlined,
                                        color: Color(0xFF9CA3AF),
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Terverifikasi',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Foto checkout belum tersedia',
                            style: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    _LocationInfo(
                      locationName: record.location?.name ?? '-',
                      distancePrefix: 'Jarak dari titik absensi: ',
                      distanceValue:
                          '${(record.checkOutDistance ?? 0).toStringAsFixed(0)}m',
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
  final String distancePrefix;
  final String distanceValue;
  final double lat;
  final double lng;

  const _LocationInfo({
    required this.locationName,
    required this.distancePrefix,
    required this.distanceValue,
    required this.lat,
    required this.lng,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDCE3F0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: const Color(0xFF9A9A9A),
              ),
              const SizedBox(width: 6),
              Text(
                locationName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              style: TextStyle(color: const Color(0xFF3D4A42), fontSize: 16),
              children: [
                TextSpan(text: distancePrefix),
                TextSpan(
                  text: distanceValue,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.my_location, size: 18, color: Color(0xFF9A9A9A)),
              const SizedBox(width: 6),
              Text(
                '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                style: TextStyle(color: const Color(0xFF3D4A42), fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
