import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:upsend_karyawan/core/api/api.dart';
import 'package:upsend_karyawan/features/auth/pages/login_page.dart';
import 'package:upsend_karyawan/features/auth/pages/register_page.dart';
import 'package:upsend_karyawan/features/splashscreen/pages/splash_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Api.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UpSend',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF006847)),
        // 2. Ganti textTheme menggunakan Google Fonts Inter
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
      ),
      home: const SplashPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register_page': (context) => const RegisterPage(),
      },
    );
  }
}
