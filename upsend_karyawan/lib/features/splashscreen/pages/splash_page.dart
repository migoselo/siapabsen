import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:upsend_karyawan/features/auth/pages/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _animate = false;
  bool _fadeOut = false; // Flag tambahan untuk animasi keluar

  @override
  void initState() {
    super.initState();

    // 1. Jalankan animasi masuk (sedikit jeda 200ms agar smooth saat aplikasi terbuka)
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _animate = true;
        });
      }
    });

    // 2. Efek menghilang (Fade Out) pada detik ke 2.6
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) {
        setState(() {
          _fadeOut = true;
        });
      }
    });

    // 3. Pindah halaman tepat di detik ke 3
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _navigateNext();
      }
    });
  }

  Future<void> _navigateNext() async {
    final prefs = await SharedPreferences.getInstance();

    // aktifkan jika ingin debug on boarding
    // if (kDebugMode) {
    //   await prefs.remove('has_seen_onboarding');
    // }

    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    await prefs.remove('auth_token');
    await prefs.remove('user_name');

    if (!mounted) return;

    if (!hasSeenOnboarding) {
      Navigator.pushReplacementNamed(context, '/onboarding');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF2F3B69),
      body: SafeArea(
        child: Center(
          // Gabungan animasi masuk dan animasi keluar menggunakan _fadeOut
          child: AnimatedOpacity(
            opacity: _fadeOut ? 0 : (_animate ? 1 : 0),
            duration: Duration(
              milliseconds: _fadeOut ? 400 : 1200,
            ), // Animasi masuk lebih lambat (1.2s)
            curve: Curves.easeInOut,
            child: AnimatedScale(
              scale: _fadeOut
                  ? 1.05
                  : (_animate ? 1 : 0.85), // Efek sedikit membesar saat keluar
              duration: Duration(milliseconds: _fadeOut ? 400 : 1200),
              curve: Curves.easeOutCubic,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/images/Logo.svg',
                    width: size.width * 0.32,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'SiapAbsen',
                    style: TextStyle(
                      fontFamily: 'jakarta',
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
