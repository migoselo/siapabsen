import 'package:flutter/material.dart';
import 'package:upsend_karyawan/features/profile/widgets/profile_header.dart';

const Color kTextPrimary = Color(0xFF0F172A);
const Color kPrimary = Color.fromARGB(255, 47, 59, 105);
const Color kTextSecondary = Color(0xFF6B7280);

class GreetingHeader extends StatelessWidget {
  final String userName;

  const GreetingHeader({super.key, required this.userName});

  String _greetingByTime() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greetingByTime(),
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: kTextSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Halo, $userName',
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kPrimary,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/profile'),
          child: ClipOval(
            child: IdenticonAvatar(username: userName, size: 44.0),
          ),
        ),
      ],
    );
  }
}