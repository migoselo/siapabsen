import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:upsend_karyawan/core/api/api.dart';
import 'package:upsend_karyawan/features/auth/pages/login_page.dart';
import 'package:upsend_karyawan/features/auth/pages/register_page.dart';
import 'package:upsend_karyawan/features/splashscreen/pages/splash_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/home/bloc/home_bloc.dart';
import '../features/home/repository/home_repository.dart';
import '../features/attendance/repository/attendance_repository.dart';
import '../features/home/pages/home_page.dart';
import '../features/attendance/pages/checkin_location_page.dart';
import '../features/attendance/bloc/attendance_bloc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final attendanceRepository = AttendanceRepository();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AttendanceRepository>.value(
          value: attendanceRepository,
        ),
        RepositoryProvider<HomeRepository>(
          create: (_) =>
              HomeRepository(attendanceRepository: attendanceRepository),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<HomeBloc>(
            create: (context) =>
                HomeBloc(homeRepository: context.read<HomeRepository>()),
          ),

          BlocProvider<AttendanceBloc>(
            create: (_) => AttendanceBloc(repository: attendanceRepository),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Attendance App',
          theme: ThemeData(
            fontFamily: 'PlusJakartaSans',
            scaffoldBackgroundColor: Colors.white,
          ),
          // 1. Ubah initialRoute menjadi splash page agar dibuka pertama kali
          initialRoute: '/splash',
          routes: {
            // 2. Daftarkan SplashPage di sini
            '/splash': (context) => const SplashPage(),
            '/login': (context) => const LoginPage(),
            '/register_page': (context) => const RegisterPage(),
            '/home': (context) => const HomePage(),
            '/checkin': (context) => const CheckinLocationPage(),
          },
        ),
      ),
    );
  }
}
