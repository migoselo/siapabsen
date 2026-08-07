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

class CheckinLocationPage extends StatefulWidget {
  const CheckinLocationPage({super.key});

  @override
  State<CheckinLocationPage> createState() => _CheckinLocationPageState();
}

class _CheckinLocationPageState extends State<CheckinLocationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceBloc>().add(FetchNearbyLocations());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 25 + 24 + 25,
        leading: Padding (
          padding: const EdgeInsets.only(left: 20.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          "Check In",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
      ),
      body: BlocBuilder<AttendanceBloc, AttendanceState>(
        builder: (context, state) {
          if (state.status == AttendanceStatus.loading &&
              state.nearbyLocations.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2B3A8F)),
            );
          }

          final hasValidLocation =
              state.selectedLocation != null &&
              state.selectedLocation!.withinRadius;

          return AttendanceStepper(
            currentStep: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Text(
                    _buildSubtitle(state),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF9A9A9A),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (state.selectedLocation != null)
                    LocationCard(location: state.selectedLocation!),

                  if (state.status == AttendanceStatus.failure)
                    _ErrorBox(message: state.errorMessage),

                  if (state.status == AttendanceStatus.success &&
                      state.nearbyLocations.isEmpty)
                    const _EmptyLocationBox(),

                  // Box besar "di luar radius" DIHAPUS — cukup card + subtitle
                  const Spacer(),

                  // Tombol "Lanjut ke kamera" -> DIKUNCI kalau di luar radius
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          (hasValidLocation &&
                              state.status != AttendanceStatus.loading)
                          ? const Color(0xFF2B3A8F)
                          : const Color(0xFF9A9A9A),
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                    ),
                    onPressed:
                        (!hasValidLocation ||
                            state.status == AttendanceStatus.loading)
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CheckinCameraPage(),
                              ),
                            );
                          },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Lanjut ke kamera",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Tombol "Coba lagi" -> memicu FetchNearbyLocations
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black, width: 1.2),
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: state.status == AttendanceStatus.loading
                        ? null
                        : () {
                            context.read<AttendanceBloc>().add(
                              FetchNearbyLocations(),
                            );
                          },
                    child: state.status == AttendanceStatus.loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF2B3A8F),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.refresh,
                                color: Colors.black,
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                "Coba lagi",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
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
    );
  }

  String _buildSubtitle(AttendanceState state) {
    if (state.status == AttendanceStatus.failure) {
      return "Gagal mendeteksi lokasi";
    }
    if (state.selectedLocation != null) {
      return state.selectedLocation!.withinRadius
          ? "Lokasi Anda telah ditemukan"
          : "Anda di luar jangkauan lokasi";
    }
    return "Mencari lokasi Anda...";
  }
}

class _ErrorBox extends StatelessWidget {
  final String? message;
  const _ErrorBox({this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message ?? "Terjadi kesalahan saat mengambil lokasi.",
              style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLocationBox extends StatelessWidget {
  const _EmptyLocationBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Row(
        children: [
          Icon(Icons.location_off_outlined, color: Color(0xFFB45309)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Tidak ada lokasi kantor yang terdeteksi di sekitar Anda.",
              style: TextStyle(color: Color(0xFFB45309), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
