import 'dart:io';

import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class CameraService {
  CameraController? controller;
  CameraDescription? _frontCamera;
    final FaceDetector _faceDetector =
      FaceDetector(options: FaceDetectorOptions(performanceMode: FaceDetectorMode.fast));

  Future<void> init() async {
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
    if (controller == null || !controller!.value.isInitialized) return null;

    final XFile xfile = await controller!.takePicture();
    final inputImage = InputImage.fromFilePath(xfile.path);
    final faces = await _faceDetector.processImage(inputImage);

    if (faces.isNotEmpty) {
      return File(xfile.path);
    }

    // No face found — delete the captured file
    try {
      await File(xfile.path).delete();
    } catch (_) {}
    return null;
  }

  Future<void> dispose() async {
    try {
      await controller?.dispose();
    } catch (_) {}
    _faceDetector.close();
  }
}
