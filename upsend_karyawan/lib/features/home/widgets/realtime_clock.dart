import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import package intl

class RealtimeClockCard extends StatefulWidget {
  const RealtimeClockCard({Key? key}) : super(key: key);

  @override
  State<RealtimeClockCard> createState() => _RealtimeClockCardState();
}

class _RealtimeClockCardState extends State<RealtimeClockCard> {
  Timer? _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    // Update setiap 1 detik
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Format Waktu (Contoh: 14:35:45)
    final timeString = DateFormat('HH:mm:ss').format(_now);

    // Format Tanggal Bahasa Indonesia (Contoh: Jumat, Agustus 7, 2026)
    final dateString = DateFormat('EEEE, MMMM d, yyyy', 'id_ID').format(_now);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(255, 47, 59, 105),
            Color.fromARGB(255, 78, 98, 175),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Jam Realtime
          Text(
            timeString,
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          // Tanggal Dinamis Pas Bahasa Indonesia
          Text(
            dateString,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}