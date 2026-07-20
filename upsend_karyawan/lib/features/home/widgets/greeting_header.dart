import 'package:flutter/material.dart';
import '../../profile/widgets/profile_header.dart';

const Color kTextSecondary = Color(0xFF3D4A42);
const Color kBorder = Color(0xFFBCCAC0);

/// Nama & avatar SENGAJA dijadikan parameter, bukan diambil dari HomeBloc —
/// karena AttendanceModel gak punya data user (cuma employeeId).
/// Widget ini butuh disuapin data dari Auth/User state kamu.
class GreetingHeader extends StatelessWidget {
  final String userName;

  const GreetingHeader({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 29, left: 30),
      child: Row(
        children: [
          IdenticonAvatar(username: userName, size: 44),
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
