import 'package:flutter/material.dart';

class LocationPermissionRetryView extends StatelessWidget {
  final VoidCallback onOpenSettings;

  const LocationPermissionRetryView({
    super.key,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFEF2F2),
            ),
            child: const Icon(
              Icons.location_off_outlined,
              color: Color(0xFFDC2626),
              size: 42,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Gagal mendeteksi lokasi',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Izin lokasi diperlukan. Aktifkan izin melalui Settings.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF9A9A9A),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2F3B69),
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 0,
            ),
            onPressed: onOpenSettings,
            child: const Text(
              'Buka Pengaturan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
