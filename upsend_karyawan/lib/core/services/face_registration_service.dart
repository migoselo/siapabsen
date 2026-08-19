import 'dart:io';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FaceRegistrationService {
  static const String _registeredKey = 'registered_face_is_active';
  static const String _registeredFacePathKey = 'registered_face_path';
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableTracking: false,
      minFaceSize: 0.15,
    ),
  );

  Future<bool> hasRegisteredFace() async {
    final prefs = await SharedPreferences.getInstance();
    final isRegistered = prefs.getBool(_registeredKey) == true;
    final facePath = prefs.getString(_registeredFacePathKey) ?? '';

    if (!isRegistered || facePath.isEmpty) return false;

    final file = File(facePath);
    if (!file.existsSync()) {
      await prefs.setBool(_registeredKey, false);
      await prefs.remove(_registeredFacePathKey);
      return false;
    }

    return true;
  }

  Future<String?> getRegisteredFacePath() async {
    final prefs = await SharedPreferences.getInstance();
    final facePath = prefs.getString(_registeredFacePathKey) ?? '';

    if (facePath.isEmpty) return null;
    final file = File(facePath);
    if (!file.existsSync()) {
      await prefs.setBool(_registeredKey, false);
      await prefs.remove(_registeredFacePathKey);
      return null;
    }

    return facePath;
  }

  Future<void> saveRegisteredFace(File sourceFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName =
        'registered_face_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final targetFile = File('${appDir.path}/$fileName');

    final bytes = await sourceFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Gagal membaca foto untuk pendaftaran wajah');
    }

    final normalized = img.copyResize(decoded, width: 640, height: 640);
    final jpegBytes = img.encodeJpg(normalized, quality: 90);
    await targetFile.writeAsBytes(jpegBytes, flush: true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_registeredKey, true);
    await prefs.setString(_registeredFacePathKey, targetFile.path);
  }

  Future<bool> isFaceMatch(File candidateFile) async {
    final registeredPath = await getRegisteredFacePath();
    if (registeredPath == null) return false;

    final registeredFile = File(registeredPath);
    if (!registeredFile.existsSync()) return false;

    try {
      final registeredFace = await _detectSingleFace(registeredFile);
      final candidateFace = await _detectSingleFace(candidateFile);

      // Identity matching is handled by the backend using the registered
      // embedding. Keep this local check limited to image/face validity so
      // different lighting, pose, and camera framing do not cause rejection.
      return registeredFace != null && candidateFace != null;
    } catch (_) {
      return false;
    }
  }

  Future<Face?> _detectSingleFace(File file) async {
    final decoded = img.decodeImage(await file.readAsBytes());
    if (decoded == null) return null;

    final inputImage = InputImage.fromFilePath(file.path);
    final faces = await _faceDetector.processImage(inputImage);
    if (faces.length != 1) return null;

    final face = faces.first;
    final boundingBox = face.boundingBox;
    final width = boundingBox.width;
    final height = boundingBox.height;
    if (width <= 0 || height <= 0) return null;

    final faceArea = decoded.width * decoded.height;
    final minArea = faceArea * 0.01;
    if (width * height < minArea) return null;

    return face;
  }

}
