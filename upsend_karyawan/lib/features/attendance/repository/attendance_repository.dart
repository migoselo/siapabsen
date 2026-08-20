import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/api/api.dart';
import '../models/location_model.dart';
import '../models/attendance_model.dart';

class AttendanceRepository {
  Future<List<LocationModel>> getNearbyLocations({
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await Api.dio.get(
        '/attendances/nearby-locations',
        queryParameters: {'lat': lat, 'lng': lng},
      );
      return (response.data as List)
          .map((json) => LocationModel.fromJson(json))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Future<AttendanceModel> checkIn({
  //   required int locationId,
  //   required double lat,
  //   required double lng,
  //   required File photo,
  // }) async {
  //   try {
  //     String fileName = photo.path.split('/').last;
  //     FormData formData = FormData.fromMap({
  //       'location_id': locationId,
  //       'lat': lat,
  //       'lng': lng,
  //       'photo': await MultipartFile.fromFile(photo.path, filename: fileName),
  //     });

  //     final response = await Api.dio.post(
  //       '/attendances/check-in',
  //       data: formData,
  //     );
  //     return AttendanceModel.fromJson(response.data);
  //   } catch (e) {
  //     rethrow;
  //   }
  // }
  Future<AttendanceModel> checkIn({
    required int locationId,
    required double lat,
    required double lng,
    required File photo,
  }) async {
    try {
      String fileName = photo.path.split('/').last;
      FormData formData = FormData.fromMap({
        'location_id': locationId,
        'lat': lat,
        'lng': lng,
        'photo': await MultipartFile.fromFile(photo.path, filename: fileName),
      });

      final response = await Api.dio.post(
        '/attendances/check-in',
        data: formData,
      );
      return AttendanceModel.fromJson(response.data);
    } on DioException catch (e) {
      // Ambil pesan validasi asli dari backend (Laravel biasanya di 'message' atau 'errors')
      final data = e.response?.data;
      if (data is Map) {
        final message = data['message'] ?? data['errors']?.toString();
        throw Exception(
          message ?? 'Gagal melakukan check-in (${e.response?.statusCode})',
        );
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  // =====================================================================
  // Dikonfirmasi persis dari kode AttendanceController.php:
  //
  // GET /my-open-session -> { "open_session": {...} | null }
  //   Selalu 200, gak pernah 404. Balikin null kalau belum ada sesi terbuka.
  //
  // PATCH /{attendance}/check-out -> body WAJIB berisi lat & lng
  //   (validasi backend: 'lat' => 'required|numeric...', sama untuk lng)
  //   Response: object attendance langsung (gak dibungkus key apapun),
  //   sama polanya kayak response checkIn() di atas.
  // =====================================================================

  /// GET /my-open-session
  Future<AttendanceModel?> getTodayAttendance() async {
    try {
      final response = await Api.dio.get('/attendances/my-open-session');
      final data = response.data['open_session'];
      if (data == null) return null;
      return AttendanceModel.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  /// PATCH /{attendance}/check-out
  /// lat & lng WAJIB — backend akan reject 422 kalau kosong.
  Future<AttendanceModel> checkOut({
    required int attendanceId,
    required double lat,
    required double lng,
    File? photo,
  }) async {
    try {
      final response = await Api.dio.patch(
        '/attendances/$attendanceId/check-out',
        data: FormData.fromMap({
          'lat': lat,
          'lng': lng,
          if (photo != null)
            'photo': await MultipartFile.fromFile(
              photo.path,
              filename: photo.path.split('/').last,
            ),
        }),
      );
      return AttendanceModel.fromJson(response.data);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map) {
        final message = data['message'] ?? data['errors']?.toString();
        throw Exception(
          message ?? 'Gagal melakukan check-out (${e.response?.statusCode})',
        );
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<AttendanceModel>> getHistory() async {
    try {
      final response = await Api.dio.get('/attendances/my-history');
      final list = response.data['data'] as List;
      return list.map((json) => AttendanceModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // ========== FACE RECOGNITION METHODS ==========

  /// GET /face/status
  /// Check if user has registered face
  Future<bool> checkFaceRegistrationStatus() async {
    try {
      final response = await Api.dio.get('/face/status');
      return response.data['registered'] ?? false;
    } catch (e) {
      rethrow;
    }
  }

  /// POST /face/register
  /// Register user's face with a photo
  Future<Map<String, dynamic>> registerFace(
    File photo,
    List<double> embedding,
  ) async {
    try {
      String fileName = photo.path.split('/').last;
      FormData formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(photo.path, filename: fileName),
      });
      for (var index = 0; index < embedding.length; index++) {
        formData.fields.add(
          MapEntry('embedding[$index]', '${embedding[index]}'),
        );
      }

      final response = await Api.dio.post('/face/register', data: formData);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map) {
        final message = data['message'] ?? data['errors']?.toString();
        throw Exception(
          message ?? 'Gagal mendaftarkan wajah (${e.response?.statusCode})',
        );
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// POST /face/verify
  /// Verify user's current face against registered face
  /// Returns: { matched: bool, message: string, score?: double, best_distance?: double }
  Future<Map<String, dynamic>> verifyFace(
    File photo,
    List<double> embedding,
  ) async {
    try {
      String fileName = photo.path.split('/').last;
      FormData formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(photo.path, filename: fileName),
      });
      for (var index = 0; index < embedding.length; index++) {
        formData.fields.add(
          MapEntry('embedding[$index]', '${embedding[index]}'),
        );
      }

      final response = await Api.dio.post('/face/verify', data: formData);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      // Face verification mungkin return 403 (matched: false)
      // atau 422 (error). Handle both cases.
      final data = e.response?.data;
      if (data is Map) {
        // If 403, it's a valid response indicating face mismatch
        if (e.response?.statusCode == 403) {
          return {
            'matched': false,
            'message': data['message'] ?? 'Wajah tidak cocok',
            'best_distance': data['best_distance'] ?? 1.0,
          };
        }
        // For other errors
        final message = data['message'] ?? data['errors']?.toString();
        throw Exception(
          message ?? 'Gagal memverifikasi wajah (${e.response?.statusCode})',
        );
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}
