import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

enum RiwayatCalendarMode { year, month, range, single }

class RiwayatCalendarSelection {
  final RiwayatCalendarMode mode;
  final DateTime date;
  final DateTimeRange? range;

  const RiwayatCalendarSelection({
    required this.mode,
    required this.date,
    this.range,
  });
}

class RiwayatCalendarDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTimeRange? initialRange;
  final DateTime today;
  final RiwayatCalendarMode initialMode;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool allowModeSwitch;

  const RiwayatCalendarDialog({
    super.key,
    required this.initialDate,
    required this.initialRange,
    required this.today,
    this.initialMode = RiwayatCalendarMode.range,
    this.firstDate,
    this.lastDate,
    this.allowModeSwitch = true,
  });

  @override
  State<RiwayatCalendarDialog> createState() => _RiwayatCalendarDialogState();
}

class _RiwayatCalendarDialogState extends State<RiwayatCalendarDialog> {
  late final DateTime _selectedDate;
  late DateTime _visibleMonth;
  late RiwayatCalendarMode _mode;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  DateTime get _firstDate => widget.firstDate ?? DateTime(2000);
  DateTime get _lastDate => widget.lastDate ?? widget.today;
  bool get _allowModeSwitch =>
      widget.allowModeSwitch &&
      widget.initialMode != RiwayatCalendarMode.single;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _selectedDate = widget.initialDate;
    _visibleMonth = DateTime(widget.initialDate.year, widget.initialDate.month);
    _rangeStart = widget.initialRange?.start;
    _rangeEnd = widget.initialRange?.end;
  }

  bool _isSameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  void _changeMonth(int offset) {
    final nextMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + offset,
    );
    if (nextMonth.year < _firstDate.year ||
        nextMonth.isAfter(DateTime(_lastDate.year, _lastDate.month))) {
      return;
    }
    setState(() => _visibleMonth = nextMonth);
  }

  void _selectYear(int year) {
    Navigator.pop(
      context,
      RiwayatCalendarSelection(
        mode: RiwayatCalendarMode.year,
        date: DateTime(year, 1, 1),
      ),
    );
  }

  void _selectMonth(int month) {
    Navigator.pop(
      context,
      RiwayatCalendarSelection(
        mode: RiwayatCalendarMode.month,
        date: DateTime(_visibleMonth.year, month, 1),
      ),
    );
  }

  void _selectRangeDate(DateTime date) {
    setState(() {
      if (_rangeStart == null || _rangeEnd != null) {
        _rangeStart = date;
        _rangeEnd = null;
      } else if (date.isBefore(_rangeStart!)) {
        _rangeEnd = _rangeStart;
        _rangeStart = date;
      } else {
        _rangeEnd = date;
      }
    });
  }

  void _confirmRange() {
    if (_rangeStart == null || _rangeEnd == null) return;
    Navigator.pop(
      context,
      RiwayatCalendarSelection(
        mode: RiwayatCalendarMode.range,
        date: _rangeStart!,
        range: DateTimeRange(start: _rangeStart!, end: _rangeEnd!),
      ),
    );
  }

  void _selectSingleDate(DateTime date) {
    Navigator.pop(
      context,
      RiwayatCalendarSelection(mode: RiwayatCalendarMode.single, date: date),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    // Lebar responsif: maksimal 360, tapi mengecil kalau layar sempit
    // (dikurangi margin kiri-kanan supaya tidak mepet ke tepi layar).
    final dialogWidth = screenSize.width < 400
        ? screenSize.width * 0.88
        : 360.0;
    // Tinggi maksimal dibatasi ke persentase layar, dengan fallback
    // scroll kalau kontennya tetap lebih tinggi (misal font besar/aksesibilitas).
    final maxDialogHeight = screenSize.height * 0.85;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxDialogHeight),
        child: SizedBox(
          width: dialogWidth,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_mode == RiwayatCalendarMode.range ||
                    _mode == RiwayatCalendarMode.single)
                  _buildCalendarHeader(),
                if (_mode == RiwayatCalendarMode.range) _buildRangeHint(),
                _buildCalendar(),
                if (_mode == RiwayatCalendarMode.range) _buildFooterButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRangeHint() {
    final hint = _rangeStart == null
        ? 'Pilih tanggal mulai dan tanggal selesai'
        : _rangeEnd == null
        ? 'Sekarang pilih tanggal selesai'
        : 'Rentang tanggal sudah dipilih';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFB7C0DF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/images/Calendar.svg',
            width: 18,
            height: 18,
            colorFilter: const ColorFilter.mode(
              Color(0xFF2F3B69),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hint,
              style: const TextStyle(
                color: Color(0xFF2F3B69),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 8, right: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'BATAL',
              style: TextStyle(
                color: Color(0xFF2F3B69),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: _rangeStart != null && _rangeEnd != null
                ? _confirmRange
                : null,
            child: const Text(
              'OKE',
              style: TextStyle(
                color: Color(0xFF2F3B69),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
              padding: EdgeInsets.zero,
              onPressed: () => _changeMonth(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _allowModeSwitch
                        ? () =>
                              setState(() => _mode = RiwayatCalendarMode.month)
                        : null,
                    child: Text(
                      DateFormat('MMMM', 'id_ID').format(_visibleMonth),
                      style: const TextStyle(
                        color: Color(0xFF2F3B69),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _allowModeSwitch
                        ? () => setState(() => _mode = RiwayatCalendarMode.year)
                        : null,
                    child: Text(
                      '${_visibleMonth.year}',
                      style: const TextStyle(
                        color: Color(0xFF2F3B69),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
              padding: EdgeInsets.zero,
              onPressed: () => _changeMonth(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildCalendar() {
    switch (_mode) {
      case RiwayatCalendarMode.year:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () =>
                  setState(() => _mode = RiwayatCalendarMode.range),
              child: Text('${_visibleMonth.year}'),
            ),
            // YearPicker butuh tinggi terbatas (internalnya ListView tanpa
            // shrinkWrap), jadi tetap dikasih SizedBox — tapi ukurannya
            // dihitung dari layar, bukan angka mati.
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.35,
              child: YearPicker(
                firstDate: _firstDate,
                lastDate: _lastDate,
                selectedDate: _selectedDate,
                onChanged: (date) {
                  _visibleMonth = DateTime(date.year, _visibleMonth.month);
                  _selectYear(date.year);
                },
              ),
            ),
          ],
        );
      case RiwayatCalendarMode.month:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () =>
                  setState(() => _mode = RiwayatCalendarMode.range),
              child: Text('${_visibleMonth.year}'),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(8),
              itemCount: 12,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.2,
              ),
              itemBuilder: (context, index) {
                final month = index + 1;
                final date = DateTime(_visibleMonth.year, month, 1);
                final disabled = date.isAfter(_lastDate);
                final isSelected = month == _visibleMonth.month;

                return GestureDetector(
                  onTap: disabled
                      ? null
                      : () {
                          _visibleMonth = date;
                          _selectMonth(month);
                        },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected ? const Color(0xFF2F3B69) : null,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF2F3B69)
                            : const Color(0xFFC9D1E3),
                      ),
                    ),
                    child: Text(
                      DateFormat('MMM', 'id_ID').format(date),
                      style: TextStyle(
                        color: disabled
                            ? const Color(0xFF91A0BF)
                            : isSelected
                            ? Colors.white
                            : const Color(0xFF202B4D),
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      case RiwayatCalendarMode.range:
        return _buildRangeCalendar();
      case RiwayatCalendarMode.single:
        return _buildSingleCalendar();
    }
  }

  Widget _buildRangeCalendar() {
    final firstWeekday = DateTime(
      _visibleMonth.year,
      _visibleMonth.month,
      1,
    ).weekday;
    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;
    final firstCalendarDate = DateTime(
      _visibleMonth.year,
      _visibleMonth.month,
      1 - (firstWeekday - 1),
    );
    final cells = List.generate(
      42,
      (index) => firstCalendarDate.add(Duration(days: index)),
    );
    final lastCalendarDate = DateTime(
      _visibleMonth.year,
      _visibleMonth.month,
      daysInMonth,
    );
    if (lastCalendarDate.weekday == DateTime.sunday && cells.length > 35) {
      cells.removeRange(35, cells.length);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']
              .map(
                (day) => SizedBox(
                  width: 36,
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF4E62AF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 6),
        // shrinkWrap + NeverScrollableScrollPhysics: grid mengukur tingginya
        // sendiri berdasarkan konten (6 baris x 7 kolom), jadi dialog tidak
        // perlu tinggi tetap dan tidak akan crop baris terakhir lagi.
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cells.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
          ),
          itemBuilder: (context, index) {
            final date = cells[index];
            final disabled =
                date.isBefore(_firstDate) || date.isAfter(_lastDate);
            final isPreview =
                date.month != _visibleMonth.month ||
                date.year != _visibleMonth.year;
            final isStart =
                _rangeStart != null && _isSameDay(date, _rangeStart!);
            final isEnd = _rangeEnd != null && _isSameDay(date, _rangeEnd!);
            final inRange =
                _rangeStart != null &&
                _rangeEnd != null &&
                !date.isBefore(_rangeStart!) &&
                !date.isAfter(_rangeEnd!);

            return GestureDetector(
              onTap: disabled ? null : () => _selectRangeDate(date),
              child: Container(
                decoration: BoxDecoration(
                  color: inRange ? const Color(0xFFB7C0DF) : null,
                  borderRadius: BorderRadius.horizontal(
                    left: isStart ? const Radius.circular(20) : Radius.zero,
                    right: isEnd ? const Radius.circular(20) : Radius.zero,
                  ),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isStart || isEnd ? const Color(0xFF2F3B69) : null,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      color: disabled
                          ? const Color(0xFF91A0BF)
                          : isStart || isEnd
                          ? Colors.white
                          : const Color(
                              0xFF202B4D,
                            ).withValues(alpha: isPreview ? 0.45 : 1),
                      fontSize: 14,
                      fontWeight: isStart || isEnd
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSingleCalendar() {
    final firstWeekday = DateTime(
      _visibleMonth.year,
      _visibleMonth.month,
      1,
    ).weekday;
    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;
    final firstCalendarDate = DateTime(
      _visibleMonth.year,
      _visibleMonth.month,
      1 - (firstWeekday - 1),
    );
    final cells = List.generate(
      42,
      (index) => firstCalendarDate.add(Duration(days: index)),
    );
    final lastCalendarDate = DateTime(
      _visibleMonth.year,
      _visibleMonth.month,
      daysInMonth,
    );
    if (lastCalendarDate.weekday == DateTime.sunday && cells.length > 35) {
      cells.removeRange(35, cells.length);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']
              .map(
                (day) => SizedBox(
                  width: 36,
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF4E62AF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cells.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
          ),
          itemBuilder: (context, index) {
            final date = cells[index];
            final disabled =
                date.isBefore(_firstDate) || date.isAfter(_lastDate);
            final isPreview =
                date.month != _visibleMonth.month ||
                date.year != _visibleMonth.year;
            final isSelected = _isSameDay(date, _selectedDate);

            return GestureDetector(
              onTap: disabled ? null : () => _selectSingleDate(date),
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2F3B69) : null,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    color: disabled
                        ? const Color(0xFF91A0BF)
                        : isSelected
                        ? Colors.white
                        : const Color(
                            0xFF202B4D,
                          ).withValues(alpha: isPreview ? 0.45 : 1),
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
