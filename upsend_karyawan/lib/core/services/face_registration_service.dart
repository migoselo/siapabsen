import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

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

      if (registeredFace == null || candidateFace == null) {
        return false;
      }

      final registeredCrop = _cropFaceFromRect(
        img.decodeImage(await registeredFile.readAsBytes()),
        registeredFace.boundingBox,
      );
      final candidateCrop = _cropFaceFromRect(
        img.decodeImage(await candidateFile.readAsBytes()),
        candidateFace.boundingBox,
      );

      if (registeredCrop == null || candidateCrop == null) return false;

      final registeredHash = _averageHash(registeredCrop);
      final candidateHash = _averageHash(candidateCrop);

      if (registeredHash.isEmpty || candidateHash.isEmpty) return false;

      final distance = _hammingDistance(registeredHash, candidateHash);
      return distance <= 12;
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

  img.Image? _cropFaceFromRect(img.Image? image, Rect rect) {
    if (image == null) return null;

    final x = rect.left.round();
    final y = rect.top.round();
    final width = rect.width.round();
    final height = rect.height.round();

    final safeX = x.clamp(0, image.width - 1);
    final safeY = y.clamp(0, image.height - 1);
    final safeWidth = (width + safeX).clamp(1, image.width - safeX);
    final safeHeight = (height + safeY).clamp(1, image.height - safeY);

    final margin = 0.18;
    final cropX = (safeX - (safeWidth * margin)).round().clamp(
      0,
      image.width - 1,
    );
    final cropY = (safeY - (safeHeight * margin)).round().clamp(
      0,
      image.height - 1,
    );
    final cropWidth = ((safeWidth * (1 + 2 * margin))).round().clamp(
      1,
      image.width - cropX,
    );
    final cropHeight = ((safeHeight * (1 + 2 * margin))).round().clamp(
      1,
      image.height - cropY,
    );

    return img.copyCrop(
      image,
      x: cropX,
      y: cropY,
      width: cropWidth,
      height: cropHeight,
    );
  }

  String _averageHash(img.Image image) {
    final resized = img.copyResize(image, width: 8, height: 8);
    int totalBrightness = 0;
    for (int y = 0; y < resized.height; y++) {
      for (int x = 0; x < resized.width; x++) {
        final pixel = resized.getPixel(x, y);
        final brightness = ((pixel.r + pixel.g + pixel.b) / 3).round();
        totalBrightness += brightness;
      }
    }

    final averageBrightness =
        totalBrightness / (resized.width * resized.height);
    final buffer = StringBuffer();

    for (int y = 0; y < resized.height; y++) {
      for (int x = 0; x < resized.width; x++) {
        final pixel = resized.getPixel(x, y);
        final brightness = ((pixel.r + pixel.g + pixel.b) / 3).round();
        buffer.write(brightness >= averageBrightness ? '1' : '0');
      }
    }

    return buffer.toString();
  }

  int _hammingDistance(String left, String right) {
    if (left.length != right.length) return 64;

    int distance = 0;
    for (int i = 0; i < left.length; i++) {
      if (left[i] != right[i]) distance++;
    }
    return distance;
  }
}
