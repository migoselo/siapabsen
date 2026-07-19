import 'dart:async';
import 'package:flutter/material.dart';
// TODO: tambahkan dependency `geolocator` di pubspec.yaml kalau belum ada.
import 'package:geolocator/geolocator.dart';

const Color kSecondary = Color(0xFFFFD400);
const Color kTextSecondary = Color(0xFF3D4A42);
const Color kTextDisabled = Color(0xFF9A9A9A);

/// PENTING: status GPS ini TIDAK datang dari AttendanceRepository/HomeBloc.
/// Ini murni status device-level (apakah location service aktif),
/// jadi widget ini sengaja mandiri — punya state sendiri, gak perlu
/// bergantung ke HomeBloc/BlocProvider.
///
/// Widget ini cuma BACA status GPS, gak minta izin (permission request).
/// Izin lokasi seharusnya sudah di-handle di flow check-in temen kamu
/// (FetchNearbyLocations). Kalau ternyata izin belum pernah diminta sama
/// sekali sebelum homepage dibuka, badge ini akan nampilin "GPS OFF"
/// terus meskipun device-nya GPS aktif — itu bukan bug widget ini,
/// itu tanda permission belum di-request di tempat lain.
class GpsStatusCard extends StatefulWidget {
  const GpsStatusCard({super.key});

  @override
  State<GpsStatusCard> createState() => _GpsStatusCardState();
}

class _GpsStatusCardState extends State<GpsStatusCard> {
  bool _isActive = false;
  StreamSubscription<ServiceStatus>? _subscription;

  @override
  void initState() {
    super.initState();
    _checkInitialStatus();
    _subscription = Geolocator.getServiceStatusStream().listen((status) {
      if (mounted) {
        setState(() => _isActive = status == ServiceStatus.enabled);
      }
    });
  }

  Future<void> _checkInitialStatus() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (mounted) setState(() => _isActive = enabled);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _isActive ? kSecondary : kTextDisabled,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            _isActive ? 'GPS ACTIVE' : 'GPS OFF',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: kTextSecondary.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}