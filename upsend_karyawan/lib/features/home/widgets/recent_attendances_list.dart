import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../attendance/models/attendance_model.dart';
import '../../history/pages/riwayat_detail_page.dart';

const Color kTextPrimary = Color(0xFF0F172A);
const Color kTextSecondary = Color(0xFF9A9A9A);
const Color kPrimary = Color(0xFF2B3A8F);

class _HistoryEntry {
  final AttendanceModel record;
  final bool isCheckIn;
  final DateTime time;
  const _HistoryEntry({
    required this.record,
    required this.isCheckIn,
    required this.time,
  });
}

class RecentAttendanceList extends StatelessWidget {
  final List<AttendanceModel> history;
  final VoidCallback? onLihatSemua;
  final int maxItems;

  const RecentAttendanceList({
    super.key,
    required this.history,
    this.onLihatSemua,
    this.maxItems = 3,
  });

  List<_HistoryEntry> _buildEntries() {
    final entries = <_HistoryEntry>[];
    for (final r in history) {
      entries.add(
        _HistoryEntry(record: r, isCheckIn: true, time: r.checkInTime),
      );
      if (r.checkOutTime != null) {
        entries.add(
          _HistoryEntry(record: r, isCheckIn: false, time: r.checkOutTime!),
        );
      }
    }
    entries.sort((a, b) => b.time.compareTo(a.time));
    return entries.take(maxItems).toList();
  }

  @override
  Widget build(BuildContext context) {
    final entries = _buildEntries();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Presensi Terakhir',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
            GestureDetector(
              onTap: onLihatSemua,
              child: const Text(
                'Lihat Semua',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Belum ada riwayat presensi.',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 13,
                color: kTextSecondary,
              ),
            ),
          )
        else
          ...entries.map((e) => _HistoryTile(entry: e)),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final _HistoryEntry entry;
  const _HistoryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final label = entry.isCheckIn ? 'Check In' : 'Check Out';
    final iconAsset = entry.isCheckIn
        ? 'assets/images/checkin.svg'
        : 'assets/images/checkout.svg';
    final bgColor = entry.isCheckIn
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFDBEAFE);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RiwayatDetailPage(record: entry.record),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Center(
                child: SvgPicture.asset(iconAsset, width: 16, height: 16),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kTextPrimary,
                    ),
                  ),
                  Text(
                    _formatDate(entry.time),
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 11,
                      color: kTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _formatTime(entry.time),
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime value) {
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDate(DateTime value) {
    const hari = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const bulan = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${hari[value.weekday - 1]}, ${bulan[value.month - 1]} ${value.day}, ${value.year}';
  }
}
