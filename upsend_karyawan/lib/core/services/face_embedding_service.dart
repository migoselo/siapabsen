import 'dart:io';
import 'dart:typed_data';

import 'package:face_plugin/face_plugin.dart';

class FaceEmbeddingService {
  static const supportedEmbeddingLengths = {128, 192};

  Future<List<double>> extractEmbedding(File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    final faces = await FacePlugin.detectFaces(Uint8List.fromList(imageBytes));

    if (faces.isEmpty) {
      throw Exception('Wajah tidak terdeteksi. Silakan coba lagi.');
    }
    if (faces.length != 1) {
      throw Exception('Pastikan hanya satu wajah yang terlihat.');
    }

    final features = await FacePlugin.extractFeatures(
      Uint8List.fromList(imageBytes),
    );
    if (features.length != 1 ||
        !supportedEmbeddingLengths.contains(features.first.length)) {
      throw Exception('Embedding wajah tidak valid. Silakan coba lagi.');
    }

    return features.first.map((value) => value.toDouble()).toList();
  }
}
