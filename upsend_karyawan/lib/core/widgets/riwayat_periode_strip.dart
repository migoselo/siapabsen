import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'riwayat_periode_toggle.dart';

class RiwayatPeriodeStrip extends StatefulWidget {
  final PeriodeRiwayat periode;
  final DateTime anchorDate;
  final DateTime today;
  final ValueChanged<DateTime> onSelected;

  const RiwayatPeriodeStrip({
    super.key,
    required this.periode,
    required this.anchorDate,
    required this.today,
    required this.onSelected,
  });

  @override
  State<RiwayatPeriodeStrip> createState() => _RiwayatPeriodeStripState();
}

class _RiwayatPeriodeStripState extends State<RiwayatPeriodeStrip> {
  final ScrollController _controller = ScrollController();

  static const double _itemWidth = 52;
  static const double _itemGap = 8;
  static const double _itemExtent = _itemWidth + _itemGap;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _centerSelected(animate: false),
    );
  }

  @override
  void didUpdateWidget(covariant RiwayatPeriodeStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.periode != widget.periode ||
        oldWidget.anchorDate != widget.anchorDate) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _centerSelected(animate: true),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<DateTime> _buildItems() {
    switch (widget.periode) {
      case PeriodeRiwayat.mingguan:
        final startOfWeek = widget.anchorDate.subtract(
          Duration(days: widget.anchorDate.weekday - 1),
        );
        return List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
      case PeriodeRiwayat.bulanan:
        final daysInMonth = DateTime(
          widget.anchorDate.year,
          widget.anchorDate.month + 1,
          0,
        ).day;
        return List.generate(
          daysInMonth,
          (i) =>
              DateTime(widget.anchorDate.year, widget.anchorDate.month, i + 1),
        );
      case PeriodeRiwayat.tahunan:
        return List.generate(
          12,
          (i) => DateTime(widget.anchorDate.year, i + 1, 1),
        );
    }
  }

  int _findCenterIndex(List<DateTime> items) {
    final isYearly = widget.periode == PeriodeRiwayat.tahunan;

    final todayIndex = items.indexWhere((item) {
      return isYearly
          ? item.month == widget.today.month && item.year == widget.today.year
          : item.year == widget.today.year &&
                item.month == widget.today.month &&
                item.day == widget.today.day;
    });
    if (todayIndex != -1) return todayIndex;

    final anchorIndex = items.indexWhere((item) {
      return isYearly
          ? item.month == widget.anchorDate.month &&
                item.year == widget.anchorDate.year
          : item.year == widget.anchorDate.year &&
                item.month == widget.anchorDate.month &&
                item.day == widget.anchorDate.day;
    });
    return anchorIndex == -1 ? 0 : anchorIndex;
  }

  void _centerSelected({required bool animate}) {
    if (!_controller.hasClients || !mounted) return;
    final items = _buildItems();
    final index = _findCenterIndex(items);
    final viewportWidth = _controller.position.viewportDimension;

    final targetOffset =
        (index * _itemExtent) - (viewportWidth / 2) + (_itemWidth / 2);

    final clamped = targetOffset.clamp(
      0.0,
      _controller.position.maxScrollExtent,
    );

    if (animate) {
      _controller.animateTo(
        clamped,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _controller.jumpTo(clamped);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildItems();
    final isYearly = widget.periode == PeriodeRiwayat.tahunan;
    final dayLabelFormat = DateFormat('EEE', 'id_ID');
    final monthLabelFormat = DateFormat('MMM', 'id_ID');

    // langsung ListView biasa — nggak ada AnimatedSwitcher/fade lagi.
    // yang bikin "smooth" cuma animateTo di atas (posisi geser),
    // isi item ganti instan begitu periode berubah.
    return SizedBox(
      height: 64,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: _itemGap),
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = isYearly
              ? item.month == widget.anchorDate.month
              : item.year == widget.anchorDate.year &&
                    item.month == widget.anchorDate.month &&
                    item.day == widget.anchorDate.day;
          final isFuture = item.isAfter(widget.today);

          return GestureDetector(
            onTap: isFuture ? null : () => widget.onSelected(item),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _itemWidth,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1B2559) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1B2559)
                      : const Color(0xFFE1E1E1),
                ),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  isYearly
                      ? Text(
                          monthLabelFormat.format(
                            item,
                          ), // "Agu" doang, gak ada tahun lagi
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : (isFuture
                                      ? const Color(0xFFC9C9C9)
                                      : Colors.black),
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              dayLabelFormat.format(item),
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected
                                    ? Colors.white70
                                    : (isFuture
                                          ? const Color(0xFFC9C9C9)
                                          : const Color(0xFF9A9A9A)),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.day.toString().padLeft(2, '0'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : (isFuture
                                          ? const Color(0xFFC9C9C9)
                                          : Colors.black),
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
