import 'package:intl/intl.dart';
import '../../history/bloc/history_bloc.dart';
import '../../history/bloc/history_event.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/services/camera_service.dart';
import '../../../core/services/face_embedding_service.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../repository/attendance_repository.dart';
import '../../home/bloc/home_bloc.dart';
import '../../home/bloc/home_event.dart';

class CheckoutCameraPage extends StatefulWidget {
  final int attendanceId;

  const CheckoutCameraPage({super.key, required this.attendanceId});

  @override
  State<CheckoutCameraPage> createState() => _CheckoutCameraPageState();
}

class _CheckoutCameraPageState extends State<CheckoutCameraPage> {
  final CameraService _cameraService = CameraService();
  bool _cameraInitialized = false;
  bool _cameraInitInProgress = false;
  bool _cameraPermissionDenied = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureCameraInitialized();
    });
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

  Future<void> _ensureCameraInitialized() async {
    if (_cameraInitialized || _cameraInitInProgress) return;

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
      if (!mounted) return;
      setState(() {
        _cameraInitialized = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cameraPermissionDenied = true;
      });
      AppSnackbar.error(context, 'Gagal memulai kamera: ${e.toString()}');
    } finally {
      _cameraInitInProgress = false;
    }
  }

  Future<void> _captureAndSubmit() async {
    if (_isProcessing) return;
    if (!_cameraInitialized || _cameraService.controller == null) {
      AppSnackbar.error(context, 'Kamera belum siap');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final file = await _cameraService.takePictureIfFaceDetected();
      if (!mounted) return;
      if (file == null) {
        AppSnackbar.warning(
          context,
          'Wajah tidak terdeteksi. Pastikan Anda menghadap kamera.',
        );
        return;
      }

      // Gunakan AttendanceRepository untuk backend API calls
      final attendanceRepository = AttendanceRepository();

      // Check apakah user sudah mendaftar wajah
      final isRegistered = await attendanceRepository
          .checkFaceRegistrationStatus();
      if (!mounted) return;
      if (!isRegistered) {
        AppSnackbar.error(
          context,
          'Anda belum mendaftar wajah. Silakan daftar wajah di profil terlebih dahulu.',
        );
        return;
      }

      // Backend mendeteksi wajah, membuat encoding, dan membandingkan
      // dengan encoding milik user sebelum checkout dilanjutkan.
      final embedding = await FaceEmbeddingService().extractEmbedding(file);
      final verificationResult = await attendanceRepository.verifyFace(
        file,
        embedding,
      );
      if (!mounted) return;
      final matched = verificationResult['matched'] as bool? ?? false;

      if (!matched) {
        AppSnackbar.error(
          context,
          verificationResult['message'] ??
              'Wajah tidak cocok dengan wajah yang sudah didaftarkan.',
        );
        return;
      }

      // Wajah cocok, lanjut proses check-out
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      final attendance = await attendanceRepository.checkOut(
        attendanceId: widget.attendanceId,
        lat: position.latitude,
        lng: position.longitude,
        photo: file,
      );

      if (!mounted) return;
      _showSuccessDialog(attendance.checkOutTime ?? DateTime.now());
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, 'Gagal melakukan checkout: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  bool _successDialogShown = false;

  void _showSuccessDialog(DateTime checkOutTime) {
    if (_successDialogShown) return;
    _successDialogShown = true;

    final local = checkOutTime.toLocal();
    final timeText = DateFormat('HH:mm').format(local);
    final dateText = DateFormat('d MMMM yyyy', 'id_ID').format(local);

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
                "Checkout Tersimpan",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Anda pulang pukul",
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
                "Berhasil checkout pada tanggal $dateText",
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
        context.read<HomeBloc>().add(const HomeStarted());
        context.read<HistoryBloc>().add(const HistoryFetchRequested());
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
    final isBusy = _isProcessing || _cameraInitInProgress;
    Widget previewChild;

    if (!_cameraInitialized) {
      String message;
      if (_cameraPermissionDenied) {
        message = 'Izin kamera diperlukan';
      } else {
        message = 'Menunggu kamera...';
      }
      previewChild = Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey.shade100,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Center(child: Text(message)),
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
                          child: CameraPreview(_cameraService.controller!),
                        ),
                      ),
                    )
                  : const Center(child: CircularProgressIndicator()),
              if (isBusy)
                Container(
                  color: Colors.black.withValues(alpha: 0.35),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Check Out',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 12),
              const Text(
                'Pastikan wajah Anda terdeteksi',
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
                    onPressed: isBusy ? null : _captureAndSubmit,
                    child: isBusy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Checkout Sekarang',
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
        ),
      ),
    );
  }
}
