import 'package:flutter/material.dart';
import 'package:upsend_karyawan/features/auth/pages/login_page.dart';
import 'package:upsend_karyawan/features/onboarding/pages/onboarding_screen.dart';
import 'package:upsend_karyawan/features/splashscreen/pages/splash_page.dart';
import 'package:upsend_karyawan/core/theme/app_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/home/bloc/home_bloc.dart';
import '../features/home/repository/home_repository.dart';
import '../features/attendance/repository/attendance_repository.dart';
import '../features/home/pages/home_page.dart';
import '../features/profile/pages/profile_page.dart';
import 'package:upsend_karyawan/features/profile/widgets/minidenticon_generator.dart';
import '../features/attendance/pages/checkin_location_page.dart';
import '../features/attendance/bloc/attendance_bloc.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../features/auth/repository/auth_repository.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final attendanceRepository = AttendanceRepository();
    final authRepository = AuthRepository();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AttendanceRepository>.value(
          value: attendanceRepository,
        ),
        RepositoryProvider<AuthRepository>.value(value: authRepository),
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
          BlocProvider<AuthBloc>(
            create: (context) =>
                AuthBloc(authRepository: context.read<AuthRepository>())
                  ..add(const AuthCheckRequested()),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Attendance App',
          theme: AppTheme.lightTheme,
          initialRoute: '/splash',
          routes: {
            '/splash': (context) => const SplashPage(),
            '/onboarding': (context) => const OnboardingScreen(),
            '/login': (context) => const LoginPage(),
            '/profile': (context) => const ProfilePage(),
            '/home': (context) => const HomePage(),
            '/checkin': (context) => const CheckinLocationPage(),
          },
        ),
      ),
    );
  }
}
