import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const Color kBorder = Color(0xFFE5E7EB);
const Color kTextPrimary = Color(0xFF0F172A);
const Color kTextSecondary = Color(0xFF6B7280);

class AttendanceInfoBoxes extends StatelessWidget {
  final DateTime? checkInTime;
  final String? locationName;
  final DateTime? checkOutTime;

  const AttendanceInfoBoxes({
    super.key,
    required this.checkInTime,
    required this.locationName,
    required this.checkOutTime,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _InfoBox(
            iconAsset: 'assets/images/checkin.svg',
            label: 'Check In',
            timeText: checkInTime != null ? _formatTime(checkInTime!) : '--:--',
            subtitle: checkInTime != null ? (locationName ?? '-') : 'Belum Check In',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InfoBox(
            iconAsset: 'assets/images/checkout.svg',
            label: 'Check Out',
            timeText: checkOutTime != null ? _formatTime(checkOutTime!) : '--:--',
            subtitle: checkOutTime != null ? 'Selesai' : 'Belum Check Out',
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime value) {
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _InfoBox extends StatelessWidget {
  final String iconAsset;
  final String label;
  final String timeText;
  final String subtitle;

  const _InfoBox({
    required this.iconAsset,
    required this.label,
    required this.timeText,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(iconAsset, width: 16, height: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            timeText,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: kTextSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}