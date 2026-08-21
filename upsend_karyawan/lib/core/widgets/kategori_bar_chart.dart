import 'package:flutter/material.dart';
import '../../features/attendance/models/attendance_model.dart';

class KategoriChartItem {
  final String key;
  final String label;
  final Color color;
  const KategoriChartItem(this.key, this.label, this.color);
}

class KategoriBarChart extends StatelessWidget {
  final String title;
  final List<KategoriChartItem> kategoriList;
  final Map<String, int> counts;
  final String? selectedKategori;
  final ValueChanged<String?> onKategoriTap;

  const KategoriBarChart({
    super.key,
    this.title = 'Kategori',
    required this.kategoriList,
    required this.counts,
    required this.selectedKategori,
    required this.onKategoriTap,
  });

  @override
  Widget build(BuildContext context) {
    final maxCount = counts.values.isEmpty
        ? 0
        : counts.values.reduce((a, b) => a > b ? a : b);

    // fixed — nggak akan pernah lebih tinggi/lebar dari ini, berapa pun jumlah kategorinya
    const maxBarHeight = 90.0; // dulu 130, dikecilin biar nggak "kepanjangan"
    const minBarHeight = 6.0;
    const barWidth = 26.0; // fixed width juga, nggak melar

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEDED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end, // penting: rata bawah
            children: kategoriList.map((k) {
              final count = counts[k.key] ?? 0;
              final isSelected = selectedKategori == k.key;
              final barHeight = maxCount == 0
                  ? minBarHeight
                  : minBarHeight +
                      (count / maxCount) * (maxBarHeight - minBarHeight);

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onKategoriTap(isSelected ? null : k.key),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // area tooltip — tinggi tetap walau lagi disembunyikan,
                      // supaya nggak geser-geser posisi elemen di bawahnya
                      SizedBox(
                        height: 26,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: isSelected ? 1 : 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: k.color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$count hari',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // wadah bar dengan tinggi TETAP (maxBarHeight),
                      // bar-nya rata bawah di dalam wadah ini
                      Container(
                        height: maxBarHeight,
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: barHeight,
                          width: barWidth,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? k.color
                                : k.color.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      Text(
                        k.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
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
        ],
      ),
    );
  }
}