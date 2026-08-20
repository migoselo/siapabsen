import 'package:flutter/material.dart';

enum PeriodeRiwayat { mingguan, bulanan, tahunan }

class RiwayatPeriodeToggle extends StatelessWidget {
  final PeriodeRiwayat selected;
  final ValueChanged<PeriodeRiwayat> onChanged;

  const RiwayatPeriodeToggle({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const List<MapEntry<PeriodeRiwayat, String>> _items = [
    MapEntry(PeriodeRiwayat.mingguan, 'Mingguan'),
    MapEntry(PeriodeRiwayat.bulanan, 'Bulanan'),
    MapEntry(PeriodeRiwayat.tahunan, 'Tahunan'),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _items.indexWhere((e) => e.key == selected);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / _items.length;

          return SizedBox(
            height: 36,
            child: Stack(
              children: [
                Positioned(
                  left: segmentWidth * selectedIndex,
                  top: 0,
                  bottom: 0,
                  width: segmentWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: _items.map((e) {
                    final isActive = e.key == selected;
                    return SizedBox(
                      width: segmentWidth,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(e.key),
                        child: Center(
                          child: Text(
                            e.value,
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 13,
                              fontWeight:
                                  isActive ? FontWeight.w700 : FontWeight.w500,
                              color: isActive
                                  ? const Color(0xFF1B2559)
                                  : const Color(0xFF9A9A9A),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}