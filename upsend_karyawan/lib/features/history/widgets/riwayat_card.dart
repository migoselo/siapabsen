import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../attendance/models/attendance_model.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RiwayatCard extends StatelessWidget {
  final AttendanceModel record;
  final VoidCallback onTap;

  const RiwayatCard({super.key, required this.record, required this.onTap});

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'lupa_absen':
        return 'Lupa Absen';
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
        return const Color(0xFFEF4444);
      case 'telat':
        return const Color(0xFFF5A623);
      case 'lembur':
        return const Color(0xFF2F6FEB);
      default:
        return const Color(0xFF1FAE7C);
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkIn = DateFormat('HH:mm').format(record.checkInTime.toLocal());
    final checkOut = record.checkOutTime != null
        ? DateFormat('HH:mm').format(record.checkOutTime!.toLocal())
        : '--:--';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(100),
              ),
              padding: const EdgeInsets.all(
                11,
              ), // atur jarak SVG dari tepi container
              child: SvgPicture.asset(
                'assets/images/checkin.svg',
                width: 16,
                height: 16,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF16A34A),
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.location?.name ?? '-',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$checkIn\u2013$checkOut',
                    style: TextStyle(
                      color: Color(0xFF9A9A9A),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(
                        record.status,
                      ).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _statusLabel(record.status),
                      style: TextStyle(
                        color: _statusColor(record.status),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF9A9A9A)),
          ],
        ),
      ),
    );
  }
}
