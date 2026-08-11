import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RiwayatDateStrip extends StatelessWidget {
  final DateTime selectedDate;
  final DateTime today;
  final ValueChanged<DateTime> onDateSelected;

  const RiwayatDateStrip({
    super.key,
    required this.selectedDate,
    required this.today,
    required this.onDateSelected,
  });

  List<DateTime> _generateDateList(DateTime centerDate) {
    return List.generate(7, (index) => centerDate.add(Duration(days: index - 3)));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _generateDateList(selectedDate).map((date) {
          final isSameDay = date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day;
          final isFutureDate = date.isAfter(
            DateTime(today.year, today.month, today.day, 23, 59),
          );

          return GestureDetector(
            onTap: isFutureDate ? null : () => onDateSelected(date),
            child: Container(
              width: 55,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: isSameDay ? const Color(0xFF1B2559) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isFutureDate
                      ? Colors.grey.shade300
                      : (isSameDay ? const Color(0xFF1B2559) : Colors.grey.shade300),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E', 'id_ID').format(date),
                    style: TextStyle(
                      fontSize: 12,
                      color: isFutureDate
                          ? Colors.grey.shade400
                          : (isSameDay ? Colors.white : Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isFutureDate
                          ? Colors.grey.shade400
                          : (isSameDay ? Colors.white : const Color(0xFF1B2559)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}