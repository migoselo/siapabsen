import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';
import '../../../core/services/camera_service.dart';
import 'face_registration_success_dialog.dart';

const Color kNavy = Color(0xFF2E3A6E);
const String kFontFamily = 'PlusJakartaSans';

class FaceRegistrationCameraPage extends StatefulWidget {
  const FaceRegistrationCameraPage({super.key});

  @override
  State<FaceRegistrationCameraPage> createState() => _FaceRegistrationCameraPageState();
}

class _FaceRegistrationCameraPageState extends State<FaceRegistrationCameraPage> {
  final CameraService _cameraService = CameraService();
  bool _cameraInitialized = false;
  bool _cameraPermissionDenied = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() => _cameraPermissionDenied = true);
      return;
    }
    try {
      await _cameraService.init();
      if (mounted) setState(() => _cameraInitialized = true);
    } catch (e) {
      if (mounted) {
        setState(() => _cameraPermissionDenied = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal inisialisasi kamera: $e')),
        );
      }
    }
  }

  Future<void> _captureAndSave() async {
    if (!_cameraInitialized || _cameraService.controller == null) return;

    final file = await _cameraService.takePictureIfFaceDetected();
    if (file == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wajah tidak terdeteksi. Coba lagi.')),
        );
      }
      return;
    }

    setState(() => _isSaving = true);

    // =====================================================================
    // TODO: BELUM TERSAMBUNG KE BACKEND — belum ada endpoint yang
    // dikonfirmasi buat nyimpen data wajah. Ganti delay dummy ini
    // dengan panggilan repository asli begitu endpoint-nya jelas,
    // misal: await context.read<ProfileRepository>().registerFace(file);
    // =====================================================================
    await Future.delayed(const Duration(seconds: 1)); // simulasi upload

    if (!mounted) return;
    setState(() => _isSaving = false);

    await showFaceRegistrationSuccessDialog(context);

    // Setelah popup ditutup, balik ke ProfilePage (pop 2x: kamera + intro)
    if (mounted) {
      Navigator.pop(context); // tutup camera page
      Navigator.pop(context); // tutup intro page juga
    }
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Daftarkan Wajah',
          style: TextStyle(fontFamily: kFontFamily, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _cameraPermissionDenied
                  ? const Center(
                      child: Text(
                        'Izin kamera diperlukan',
                        style: TextStyle(fontFamily: kFontFamily, color: Colors.white),
                      ),
                    )
                  : !_cameraInitialized
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _cameraService.controller != null
                              ? CameraPreview(_cameraService.controller!)
                              : const Center(child: CircularProgressIndicator(color: Colors.white)),
                        ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: (_cameraInitialized && !_isSaving) ? _captureAndSave : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kNavy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text(
                          'Ambil Foto',
                          style: TextStyle(fontFamily: kFontFamily, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}