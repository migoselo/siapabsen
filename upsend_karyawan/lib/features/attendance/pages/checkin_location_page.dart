import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';
import '../widgets/attendance_stepper.dart';
import '../widgets/location_card.dart';
import 'checkin_camera_page.dart';
import 'checkin_success_page.dart';

class CheckinLocationPage extends StatelessWidget {
  const CheckinLocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Kita bungkus dengan BlocListener di tingkat teratas Scaffold body
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Check In",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: BlocListener<AttendanceBloc, AttendanceState>(
        listenWhen: (previous, current) =>
            previous.currentStep != current.currentStep,
        listener: (context, state) {
          // Navigasi dikontrol penuh dari state BLoC di sini
          if (state.currentStep == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CheckinLocationPage()),
            );
          } else if (state.currentStep == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CheckinCameraPage()),
            );
          } else if (state.currentStep == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CheckinSuccessPage()),
            );
          }
        },
        child: BlocBuilder<AttendanceBloc, AttendanceState>(
          builder: (context, state) {
            if (state.status == AttendanceStatus.loading &&
                state.nearbyLocations.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF006D4C)),
              );
            }

            return AttendanceStepper(
              currentStep: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      "Lokasi Anda telah ditemukan",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (state.selectedLocation != null)
                      LocationCard(location: state.selectedLocation!),
                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006D4C),
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        // Memicu event foto terambil, BLoC akan mengubah currentStep menjadi 2
                        // dan BlocListener di atas akan otomatis memindahkan halaman ke kamera
                        context.read<AttendanceBloc>().add(
                          PhotoCaptured(File('dummy_photo_path.jpg')),
                        );
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Lanjut ke kamera ",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.black, width: 1.2),
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        context.read<AttendanceBloc>().add(
                          FetchNearbyLocations(),
                        );
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh, color: Colors.black, size: 18),
                          SizedBox(width: 6),
                          Text(
                            "Coba lagi",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
