import 'package:flutter/material.dart';
import '../../attendance/models/attendance_model.dart';

class KategoriPresensi {
  final String key; // WAJIB disamakan dengan value `status` dari backend
  final String label;
  final Color color;
  const KategoriPresensi(this.key, this.label, this.color);
}

// TODO: sesuaikan key ini dengan value status asli dari SSMS/API kamu
const List<KategoriPresensi> kategoriPresensiList = [
  KategoriPresensi('tepat_waktu', 'Tepat', Color(0xFF1FAE7C)),
  KategoriPresensi('telat', 'Telat', Color(0xFFF5A623)),
  KategoriPresensi('lupa_absen', 'Lupa', Color(0xFFEF4444)),
  KategoriPresensi('lembur', 'Lembur', Color(0xFF2F6FEB)),
  KategoriPresensi('cuti', 'Cuti', Color(0xFF14B8C4)),
  KategoriPresensi('izin', 'Izin', Color(0xFF8B5CF6)),
];

class RiwayatCategoryChart extends StatelessWidget {
  final List<AttendanceModel> records;
  final String? selectedKategori; // null = belum ada filter
  final ValueChanged<String?> onKategoriTap;

  const RiwayatCategoryChart({
    super.key,
    required this.records,
    required this.selectedKategori,
    required this.onKategoriTap,
  });

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{
      for (final k in kategoriPresensiList)
        k.key: records
            .where((r) => r.status.toLowerCase() == k.key.toLowerCase())
            .length,
    };
    final maxCount = counts.values.isEmpty
        ? 0
        : counts.values.reduce((a, b) => a > b ? a : b);
    const maxBarHeight = 100.0;
    const minBarHeight = 10.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEDED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kategori',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: kategoriPresensiList.map((k) {
                final count = counts[k.key] ?? 0;
                final isSelected = selectedKategori == k.key;
                final barHeight = maxCount == 0
                    ? minBarHeight
                    : minBarHeight +
                        (count / maxCount) * (maxBarHeight - minBarHeight);

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onKategoriTap(isSelected ? null : k.key),
                  child: Container(
                    width: 56,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // muncul cuma pas bar-nya ditap
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: isSelected ? 1 : 0,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: k.color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$count hari',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: barHeight,
                          width: 26,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? k.color
                                : k.color.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected
                                ? Border.all(color: k.color, width: 2)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          k.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w400,
                            color: isSelected
                                ? const Color(0xFF1B2559)
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}