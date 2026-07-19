import 'package:flutter/material.dart';

const Color kTextSecondary = Color(0xFF3D4A42);
const Color kBorder = Color(0xFFBCCAC0);

/// Nama & avatar SENGAJA dijadikan parameter, bukan diambil dari HomeBloc —
/// karena AttendanceModel gak punya data user (cuma employeeId).
/// Widget ini butuh disuapin data dari Auth/User state kamu.
/// TODO: sambungkan ke Auth/User bloc/state project kamu di tempat widget
/// ini dipakai (bukan di dalam widget ini sendiri, biar tetap reusable).
class GreetingHeader extends StatelessWidget {
  final String userName;
  final String? avatarUrl;

  const GreetingHeader({
    super.key,
    required this.userName,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 29, left: 30),
      child: Row(
        children: [
          ClipOval(
            child: Container(
              width: 44,
              height: 44,
              color: kBorder.withOpacity(0.3),
              child: avatarUrl != null
                  ? Image.network(avatarUrl!, fit: BoxFit.cover)
                  : const Icon(Icons.person, color: kTextSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Halo, $userName',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: kTextSecondary,
              height: 28 / 22,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}