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
  }) async {
    try {
      final response = await Api.dio.patch(
        '/attendances/$attendanceId/check-out',
        data: {'lat': lat, 'lng': lng},
      );
      return AttendanceModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}
