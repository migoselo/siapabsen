import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../home/bloc/home_bloc.dart';
import '../../home/bloc/home_event.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';
import '../widgets/attendance_stepper.dart';

class CheckinSuccessPage extends StatelessWidget {
  const CheckinSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          "Check In",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: BlocBuilder<AttendanceBloc, AttendanceState>(
        builder: (context, state) {
          final checkInTime = state.attendanceResult?.checkInTime.toLocal();

          final timeText = checkInTime != null
              ? DateFormat('HH:mm').format(checkInTime)
              : '--:--';

          final dateText = checkInTime != null
              ? DateFormat('d MMMM yyyy', 'id_ID').format(checkInTime)
              : '-';

          return AttendanceStepper(
            currentStep: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 160,
                        width: 90,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.blueGrey.shade800,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF2B3A8F),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Icon(
                        Icons.accessibility_new,
                        size: 140,
                        color: Colors.blueGrey.shade800,
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  const Text(
                    "Absen Sukses",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Anda masuk pukul",
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeText,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 62,
                      color: Color(0xFF2B3A8F),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Berhasil absen pada tanggal $dateText",
                    style: const TextStyle(
                      color: Color(0xFF2B3A8F),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2B3A8F),
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      context.read<AttendanceBloc>().add(ResetAttendance());
                      context.read<HomeBloc>().add(const HomeStarted());
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    child: const Text(
                      "Kembali ke beranda",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
