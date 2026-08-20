import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum RiwayatCalendarMode { year, month, range }

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

  const RiwayatCalendarDialog({
    super.key,
    required this.initialDate,
    required this.initialRange,
    required this.today,
  });

  @override
  State<RiwayatCalendarDialog> createState() => _RiwayatCalendarDialogState();
}

class _RiwayatCalendarDialogState extends State<RiwayatCalendarDialog> {
  static final DateTime _firstDate = DateTime(2020);
  late final DateTime _selectedDate;
  late DateTime _visibleMonth;
  RiwayatCalendarMode _mode = RiwayatCalendarMode.range;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  DateTime get _lastDate => widget.today;

  @override
  void initState() {
    super.initState();
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
        Navigator.pop(
          context,
          RiwayatCalendarSelection(
            mode: RiwayatCalendarMode.range,
            date: _rangeStart!,
            range: DateTimeRange(start: _rangeStart!, end: _rangeEnd!),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SizedBox(
        width: 360,
        height: 320,
        child: Column(
          children: [
            if (_mode == RiwayatCalendarMode.range) _buildCalendarHeader(),
            Expanded(child: _buildCalendar()),
          ],
        ),
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
                    onTap: () =>
                        setState(() => _mode = RiwayatCalendarMode.month),
                    child: Text(
                      DateFormat('MMMM', 'id_ID').format(_visibleMonth),
                      style: const TextStyle(
                        color: Color(0xFF1B2559),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _mode = RiwayatCalendarMode.year),
                    child: Text(
                      '${_visibleMonth.year}',
                      style: const TextStyle(
                        color: Color(0xFF91A0BF),
                        fontSize: 13,
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
          children: [
            TextButton(
              onPressed: () =>
                  setState(() => _mode = RiwayatCalendarMode.range),
              child: Text('${_visibleMonth.year}'),
            ),
            Expanded(
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
          children: [
            TextButton(
              onPressed: () =>
                  setState(() => _mode = RiwayatCalendarMode.range),
              child: Text('${_visibleMonth.year}'),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: 12,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemBuilder: (context, index) {
                  final month = index + 1;
                  final date = DateTime(_visibleMonth.year, month, 1);
                  final disabled = date.isAfter(_lastDate);
                  return OutlinedButton(
                    onPressed: disabled
                        ? null
                        : () {
                            _visibleMonth = date;
                            _selectMonth(month);
                          },
                    child: Text(DateFormat('MMM', 'id_ID').format(date)),
                  );
                },
              ),
            ),
          ],
        );
      case RiwayatCalendarMode.range:
        return _buildRangeCalendar();
    }
  }

  Widget _buildRangeCalendar() {
    final firstWeekday =
        DateTime(_visibleMonth.year, _visibleMonth.month, 1).weekday;
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
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
        Expanded(
          child: GridView.builder(
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
              final isPreview = date.month != _visibleMonth.month ||
                  date.year != _visibleMonth.year;
              final isStart =
                  _rangeStart != null && _isSameDay(date, _rangeStart!);
              final isEnd =
                  _rangeEnd != null && _isSameDay(date, _rangeEnd!);
              final inRange = _rangeStart != null &&
                  _rangeEnd != null &&
                  !date.isBefore(_rangeStart!) &&
                  !date.isAfter(_rangeEnd!);

              return GestureDetector(
                onTap: disabled ? null : () => _selectRangeDate(date),
                child: Container(
                  decoration: BoxDecoration(
                    color: inRange ? const Color(0xFF4E62AF) : null,
                    borderRadius: BorderRadius.horizontal(
                      left: isStart
                          ? const Radius.circular(20)
                          : Radius.zero,
                      right: isEnd
                          ? const Radius.circular(20)
                          : Radius.zero,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isStart || isEnd
                          ? const Color(0xFF2F3B69)
                          : null,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        color: disabled
                            ? const Color(0xFF91A0BF)
                            : isStart || isEnd
                            ? Colors.white
                            : const Color(0xFF202B4D).withValues(
                                alpha: isPreview ? 0.45 : 1,
                              ),
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
        ),
      ],
    );
  }
}