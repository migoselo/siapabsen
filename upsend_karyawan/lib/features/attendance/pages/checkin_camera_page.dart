import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

import '../bloc/attendance_bloc.dart';
import '../bloc/attendance_event.dart';
import '../bloc/attendance_state.dart';
import '../../../core/services/camera_service.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../home/bloc/home_bloc.dart';
import '../../home/bloc/home_event.dart';

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
  bool _successDialogShown = false;

  // Flag lokal terpisah dari AttendanceStatus.loading, karena proses
  // "ambil foto + deteksi wajah" itu terjadi SEBELUM SubmitCheckIn
  // di-dispatch ke bloc, jadi belum tercermin di state.status.
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _cameraService.dispose();
    super.dispose();
  }

  Future<void> _ensureCameraInitializedIfNeeded(AttendanceState state) async {
    if (_cameraInitialized || _cameraInitInProgress) return;
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
      AppSnackbar.error(context, 'Gagal memulai kamera: ${e.toString()}');
    } finally {
      _cameraInitInProgress = false;
    }
  }

  // Satu-satunya aksi tombol sekarang: ambil foto -> cek wajah -> langsung submit
  Future<void> _captureAndSubmit(AttendanceState state) async {
    if (_isProcessing) return;

    if (!_cameraInitialized || _cameraService.controller == null) {
      AppSnackbar.error(context, 'Kamera belum siap');
      return;
    }

    if (state.selectedLocation == null ||
        state.latitude == null ||
        state.longitude == null) {
      AppSnackbar.error(context, 'Lokasi check-in belum tersedia.');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final file = await _cameraService.takePictureIfFaceDetected();

      if (file == null) {
        AppSnackbar.warning(
          context,
          'Wajah tidak terdeteksi. Pastikan wajah menghadap kamera.',
        );
        return;
      }

      // Simpan foto ke state bloc, lalu LANGSUNG submit tanpa jeda konfirmasi.
      // Bloc memproses event secara berurutan, jadi SubmitCheckIn dijamin
      // jalan setelah PhotoCaptured selesai di-emit.
      context.read<AttendanceBloc>().add(PhotoCaptured(file));
      context.read<AttendanceBloc>().add(SubmitCheckIn());
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog(AttendanceState state) {
    if (_successDialogShown) return;
    _successDialogShown = true;

    final checkInTime = state.attendanceResult?.checkInTime.toLocal();
    final timeText = checkInTime != null
        ? DateFormat('HH:mm').format(checkInTime)
        : '--:--';
    final dateText = checkInTime != null
        ? DateFormat('d MMMM yyyy', 'id_ID').format(checkInTime)
        : '-';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Presensi Tersimpan",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
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
                  fontSize: 56,
                  color: Color(0xFF2B3A8F),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Berhasil presensi pada tanggal $dateText",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF2B3A8F),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      if (mounted) {
        context.read<AttendanceBloc>().add(ResetAttendance());
        context.read<HomeBloc>().add(const HomeStarted());
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
      }
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            context.read<AttendanceBloc>().add(PreviousStep());
            Navigator.of(context).pop();
          },
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
      body: BlocListener<AttendanceBloc, AttendanceState>(
        listenWhen: (previous, current) =>
            previous.attendanceResult != current.attendanceResult ||
            previous.status != current.status,
        listener: (context, state) {
          if (state.status == AttendanceStatus.success &&
              state.attendanceResult != null &&
              state.currentStep >= 3) {
            _showSuccessDialog(state);
          } else if (state.status == AttendanceStatus.failure &&
              state.errorMessage != null) {
            AppSnackbar.error(context, state.errorMessage!);
          }
        },
        child: BlocBuilder<AttendanceBloc, AttendanceState>(
          builder: (context, state) {
            _ensureCameraInitializedIfNeeded(state);

            // Preview SELALU tampilkan kamera live (tidak ada lagi tahap
            // preview hasil foto), kecuali saat permission/loading awal.
            Widget previewChild;

            if (!_cameraInitialized) {
              Widget placeholder;
              if (_cameraPermissionDenied) {
                placeholder = const Center(
                  child: Text('Izin kamera diperlukan'),
                );
              } else if (state.selectedLocation == null &&
                  state.latitude == null) {
                placeholder = const Center(child: Text('Menunggu lokasi...'));
              } else {
                placeholder = const Center(child: CircularProgressIndicator());
              }
              previewChild = Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey.shade100,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: placeholder,
                ),
              );
            } else {
              previewChild = Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey.shade100,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _cameraService.controller != null
                          ? SizedBox.expand(
                              child: FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: _cameraService
                                      .controller!
                                      .value
                                      .previewSize!
                                      .height,
                                  height: _cameraService
                                      .controller!
                                      .value
                                      .previewSize!
                                      .width,
                                  child: CameraPreview(
                                    _cameraService.controller!,
                                  ),
                                ),
                              ),
                            )
                          : const Center(child: CircularProgressIndicator()),
                      // Overlay loading saat proses ambil foto / submit berjalan
                      if (_isProcessing ||
                          state.status == AttendanceStatus.loading)
                        Container(
                          color: Colors.black.withOpacity(0.35),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }

            final isBusy =
                _isProcessing || state.status == AttendanceStatus.loading;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  const Text(
                    "Pastikan wajah Anda terdeteksi",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF9A9A9A),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(child: previewChild),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2B3A8F),
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: isBusy
                            ? null
                            : () => _captureAndSubmit(state),
                        child: isBusy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Simpan',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}