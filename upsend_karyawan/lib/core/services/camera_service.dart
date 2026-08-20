import 'dart:io';

import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class CameraService {
  CameraController? controller;
  CameraDescription? _frontCamera;
  bool _captureInProgress = false;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      minFaceSize:
          0.15, // toleransi ukuran wajah minimal dalam frame, biar gak terlalu strict
    ),
  );

  Future<void> init() async {
    if (controller?.value.isInitialized == true) return;

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw Exception('No camera available on this device');
    }

    _frontCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    controller = CameraController(
      _frontCamera!,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await controller!.initialize();
    } catch (e) {
      // ensure controller disposed on failure
      await controller?.dispose();
      controller = null;
      rethrow;
    }
  }

  Future<File?> takePictureIfFaceDetected() async {
    if (_captureInProgress ||
        controller == null ||
        !controller!.value.isInitialized) {
      return null;
    }

    _captureInProgress = true;
    try {
      await Future.delayed(const Duration(milliseconds: 300));

      final XFile xfile = await controller!.takePicture();
      final inputImage = InputImage.fromFilePath(xfile.path);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.length == 1) {
        return File(xfile.path);
      }

      try {
        await File(xfile.path).delete();
      } catch (_) {}
      return null;
    } finally {
      _captureInProgress = false;
    }
  }

  Future<void> dispose() async {
    try {
      await controller?.dispose();
    } catch (_) {}
    _faceDetector.close();
  }
}
