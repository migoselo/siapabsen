import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';

import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';
import '../widgets/attendance_stepper.dart';
import '../widgets/selfie_preview.dart';
import '../../../core/services/camera_service.dart';

class CheckinCameraPage extends StatefulWidget {
  const CheckinCameraPage({super.key});

  @override
  State<CheckinCameraPage> createState() => _CheckinCameraPageState();
}

class _CheckinCameraPageState extends State<CheckinCameraPage> {
  final CameraService _cameraService = CameraService();
  bool _cameraInitialized = false;
  bool _cameraInitInProgress = false;
  bool _cameraPermissionDenied = false;

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  Future<void> _ensureCameraInitializedIfNeeded(AttendanceState state) async {
    if (_cameraInitialized || _cameraInitInProgress) return;

    // Only initialize camera when a location has been selected / detected
    if (state.selectedLocation == null && state.latitude == null) return;

    _cameraInitInProgress = true;
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() {
        _cameraPermissionDenied = true;
        _cameraInitInProgress = false;
      });
      return;
    }

    try {
      await _cameraService.init();
      setState(() {
        _cameraInitialized = true;
      });
    } catch (e) {
      setState(() {
        _cameraPermissionDenied = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal inisialisasi kamera: ${e.toString()}')),
      );
    } finally {
      _cameraInitInProgress = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            context.read<AttendanceBloc>().add(PreviousStep());
          },
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
      body: BlocBuilder<AttendanceBloc, AttendanceState>(
        builder: (context, state) {
          // initialize camera when location is ready
          _ensureCameraInitializedIfNeeded(state);

          Widget previewChild;

          if (state.capturedPhoto != null) {
            previewChild = SelfiePreview(photoFile: state.capturedPhoto);
          } else if (!_cameraInitialized) {
            if (_cameraPermissionDenied) {
              previewChild = const Center(child: Text('Izin kamera diperlukan'));
            } else if (state.selectedLocation == null && state.latitude == null) {
              previewChild = const Center(child: Text('Menunggu lokasi...'));
            } else {
              previewChild = const Center(child: CircularProgressIndicator());
            }
            previewChild = Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey.shade100,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: previewChild,
              ),
            );
          } else {
            // camera initialized
            previewChild = Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey.shade100,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _cameraService.controller != null
                    ? CameraPreview(_cameraService.controller!)
                    : const Center(child: CircularProgressIndicator()),
              ),
            );
          }

          return AttendanceStepper(
            currentStep: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Expanded(child: previewChild),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006D4C),
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: state.status == AttendanceStatus.loading
                          ? null
                          : () async {
                              // If photo already captured -> submit
                              if (state.capturedPhoto != null) {
                                context.read<AttendanceBloc>().add(SubmitCheckIn());
                                return;
                              }

                              // Ensure camera ready
                              if (!_cameraInitialized || _cameraService.controller == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Kamera belum siap')),
                                );
                                return;
                              }

                              final file = await _cameraService.takePictureIfFaceDetected();
                              if (file != null) {
                                context.read<AttendanceBloc>().add(PhotoCaptured(file));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Foto berhasil diambil')),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Wajah tidak terdeteksi. Coba lagi.')),
                                );
                              }
                            },
                      child: state.status == AttendanceStatus.loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  state.capturedPhoto != null ? 'Submit Check-in' : 'Ambil Foto',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (state.capturedPhoto == null) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.camera_alt_outlined,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ]
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
