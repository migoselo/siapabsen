import 'package:flutter/material.dart';

const Color kSecondary = Color(0xFFFFD400);
const Color kSurface = Color(0xFFFFFFFF);
const Color kBorder = Color(0xFFBCCAC0);
const Color kTextPrimary = Color(0xFF000000);
const Color kTextSecondary = Color(0xFF3D4A42);

/// Kartu status attendance. Parameter diambil dari HomeState di layer
/// pemanggil (HomePage) — widget ini sendiri gak tau soal HomeBloc,
/// biar tetap reusable/testable terpisah.
class AttendanceStatusCard extends StatelessWidget {
  final bool isCheckedIn;
  final String? locationName; // null kalau belum check-in (lihat catatan di home_state.dart)
  final DateTime? checkInTime; // dari AttendanceModel.checkInTime, null kalau belum check-in

  const AttendanceStatusCard({
    super.key,
    required this.isCheckedIn,
    this.locationName,
    this.checkInTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 352,
      height: 166,
      decoration: BoxDecoration(
        color: kSurface,
        border: Border.all(color: kBorder, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 6,
            decoration: const BoxDecoration(
              color: kSecondary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 24, left: 18, right: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'STATUS SAAT INI',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kTextSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCheckedIn ? 'Sudah Check In' : 'Belum Check In',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: kTextPrimary),
                  ),
                  const SizedBox(height: 8),
                  _IconText(icon: Icons.location_on_outlined, text: locationName ?? '-'),
                  const SizedBox(height: 8),
                  _IconText(icon: Icons.calendar_today_outlined, text: _formatToday()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tanggal hari ini dihitung lokal (device), bukan dari checkInTime —
  // supaya tetap nampilin tanggal hari ini meski user belum check-in.
  String _formatToday() {
    final now = DateTime.now();
    const hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const bulan = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return '${hari[now.weekday - 1]}, ${now.day} ${bulan[now.month - 1]} ${now.year}';
  }
}

class _IconText extends StatelessWidget {
  final IconData icon;
  final String text;
  const _IconText({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 12, height: 15, child: Icon(icon, size: 12, color: kTextSecondary)),
        const SizedBox(width: 2.5),
        Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kTextSecondary)),
      ],
    );
  }
}