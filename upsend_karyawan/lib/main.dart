import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/home/bloc/home_bloc.dart';
import '../features/home/repository/home_repository.dart';
import '../features/attendance/repository/attendance_repository.dart'; // path ke file punya temen kamu
import '../features/home/pages/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Satu instance AttendanceRepository dipakai bareng-bareng
    // (HomeBloc lewat HomeRepository, dan AttendanceBloc punya temen kamu)
    // — supaya gak ada dua instance terpisah yang manggil API sendiri-sendiri.
    final attendanceRepository = AttendanceRepository();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AttendanceRepository>.value(value: attendanceRepository),
        RepositoryProvider<HomeRepository>(
          create: (_) => HomeRepository(attendanceRepository: attendanceRepository),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<HomeBloc>(
            create: (context) => HomeBloc(
              homeRepository: context.read<HomeRepository>(),
            ),
          ),
          // TODO: tambahkan BlocProvider<AttendanceBloc> punya temen kamu
          // di sini juga, pakai attendanceRepository yang sama:
          // BlocProvider<AttendanceBloc>(
          //   create: (_) => AttendanceBloc(repository: attendanceRepository),
          // ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Attendance App',
          theme: ThemeData(
            fontFamily: 'PlusJakartaSans',
            scaffoldBackgroundColor: Colors.white,
          ),
          home: const HomePage(),
        ),
      ),
    );
  }
}