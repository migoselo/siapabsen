import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api.dart';
import '../../attendance/models/attendance_model.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RiwayatDetailPage extends StatelessWidget {
  final AttendanceModel record;
  const RiwayatDetailPage({super.key, required this.record});

  // Sama persis dengan label & warna di RiwayatCard — biar konsisten
  // di seluruh app untuk status yang sama.
  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'lupa_absen':
        return 'Lupa Checkout';
      case 'alpha':
        return 'Alpha';
      case 'telat':
        return 'Telat';
      case 'lembur':
        return 'Lembur';
      case 'tepat_waktu':
        return 'Tepat Waktu';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'lupa_absen':
        return const Color(0xFF0284C7);
      case 'alpha':
        return const Color(0xFFDC2626);
      case 'telat':
        return const Color(0xFFF59E0B);
      case 'lembur':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF16A34A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAbsent =
        record.status.toLowerCase() == 'alpha' || record.checkInTime == null;
    final dateText = record.checkInTime != null
        ? DateFormat(
            'EEEE, d MMMM yyyy',
            'id_ID',
          ).format(record.checkInTime!.toLocal())
        : 'Tidak ada data absensi';
    final checkInTime = isAbsent
        ? '--:--'
        : DateFormat('HH:mm').format(record.checkInTime!.toLocal());
    final checkOutTime = record.checkOutTime != null
        ? DateFormat('HH:mm').format(record.checkOutTime!.toLocal())
        : null;
    final hasValidCheckInPhoto = record.checkInPhoto.trim().isNotEmpty;
    final hasValidCheckOutPhoto =
        record.checkOutPhoto?.trim().isNotEmpty ?? false;

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    dateText,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(record.status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusLabel(record.status),
                    style: TextStyle(
                      color: _statusColor(record.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
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
                                Color(0xFF1DB677),
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
                                      child: _AuthenticatedAttendanceImage(
                                        attendanceId: record.id,
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
                                  _AuthenticatedAttendanceImage(
                                    attendanceId: record.id,
                                    fit: BoxFit.cover,
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
                              color: const Color(0xFFDBEAFE),
                              shape: BoxShape.circle,
                            ),
                            child: SvgPicture.asset(
                              'assets/images/checkout.svg',
                              width: 22,
                              height: 22,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFF2F3B69),
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
                                    child: _AuthenticatedAttendanceImage(
                                      attendanceId: record.id,
                                      checkout: true,
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
                                _AuthenticatedAttendanceImage(
                                  attendanceId: record.id,
                                  checkout: true,
                                  fit: BoxFit.cover,
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

class _AuthenticatedAttendanceImage extends StatefulWidget {
  final int attendanceId;
  final bool checkout;
  final BoxFit fit;

  const _AuthenticatedAttendanceImage({
    required this.attendanceId,
    required this.fit,
    this.checkout = false,
  });

  @override
  State<_AuthenticatedAttendanceImage> createState() =>
      _AuthenticatedAttendanceImageState();
}

class _AuthenticatedAttendanceImageState
    extends State<_AuthenticatedAttendanceImage> {
  late final Future<Uint8List> _photoFuture = _loadPhoto();

  Future<Uint8List> _loadPhoto() async {
    final suffix = widget.checkout ? 'my-checkout-photo' : 'my-photo';
    final response = await Api.dio.get(
      '/attendances/${widget.attendanceId}/$suffix',
      options: Options(responseType: ResponseType.bytes),
    );
    final data = response.data;
    if (data is Uint8List) return data;
    if (data is List<int>) return Uint8List.fromList(data);
    throw StateError('Format foto absensi tidak valid.');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _photoFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(snapshot.data!, fit: widget.fit);
        }
        if (snapshot.hasError) {
          return Container(
            color: const Color(0xFFF3F4F6),
            child: const Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                color: Color(0xFF9CA3AF),
                size: 32,
              ),
            ),
          );
        }
        return const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
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
