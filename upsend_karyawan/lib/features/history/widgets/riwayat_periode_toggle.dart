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

  @override
  Widget build(BuildContext context) {
    const items = {
      PeriodeRiwayat.mingguan: 'Mingguan',
      PeriodeRiwayat.bulanan: 'Bulanan',
      PeriodeRiwayat.tahunan: 'Tahunan',
    };

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: items.entries.map((e) {
          final isActive = e.key == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  e.value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
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
    );
  }
}