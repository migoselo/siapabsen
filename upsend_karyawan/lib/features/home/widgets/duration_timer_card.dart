import 'dart:async';
import 'package:flutter/material.dart';

/// Kartu gradient biru/ungu tua nampilin durasi kerja live.
/// Jalan terus (update tiap detik) kalau isCheckedIn true, berhenti &
/// balik ke 00:00:00 kalau belum/udah check-out.
class DurationTimerCard extends StatefulWidget {
  final bool isCheckedIn;
  final DateTime? checkInTime;
  final String dateText;

  const DurationTimerCard({
    super.key,
    required this.isCheckedIn,
    required this.checkInTime,
    required this.dateText,
  });

  @override
  State<DurationTimerCard> createState() => _DurationTimerCardState();
}

class _DurationTimerCardState extends State<DurationTimerCard> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  DateTime? _currentCheckInTime;

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant DurationTimerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isCheckedIn != widget.isCheckedIn ||
        oldWidget.checkInTime != widget.checkInTime) {
      _syncTimer();
    }
  }

  void _syncTimer() {
    _timer?.cancel();
    _currentCheckInTime = widget.checkInTime?.toLocal();

    if (_currentCheckInTime != null) {
      _updateElapsed();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateElapsed());
    } else {
      if (_elapsed != Duration.zero) {
        setState(() => _elapsed = Duration.zero);
      }
    }
  }

  void _updateElapsed() {
    if (!mounted || _currentCheckInTime == null) return;
    final elapsed = DateTime.now().toLocal().difference(_currentCheckInTime!);
    if (elapsed != _elapsed) {
      setState(() => _elapsed = elapsed);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          // NOTE: warna gradient estimasi dari gambar (biru tua ke ungu tua),
          // sesuaikan lagi kalau ada hex resmi dari desain.
          colors: [Color.fromARGB(255, 47, 59, 105), Color.fromARGB(255, 78, 98, 175)],
        ),
      ),
      child: Column(
        children: [
          Text(
            _formatDuration(_elapsed),
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.dateText,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}