import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../attendance/models/attendance_model.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RiwayatCard extends StatelessWidget {
  final AttendanceModel record;
  final VoidCallback onTap;

  const RiwayatCard({super.key, required this.record, required this.onTap});

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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(
                11,
              ), // atur jarak SVG dari tepi container
              child: SvgPicture.asset(
                'assets/images/checkin.svg',
                colorFilter: const ColorFilter.mode(
                  Color(0xFF16A34A),
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.location?.name ?? '-',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$checkIn\u2013$checkOut',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
