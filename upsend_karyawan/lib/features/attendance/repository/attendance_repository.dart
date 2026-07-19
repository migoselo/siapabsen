import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/api/api.dart'; // Sesuaikan lokasi impor core/api kamu
import '../models/location_model.dart';
import '../models/attendance_model.dart';

class AttendanceRepository {
  Future<List<LocationModel>> getNearbyLocations({
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await Api.dio.post(
        '/nearby-locations',
        data: {'lat': lat, 'lng': lng},
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

      final response = await Api.dio.post('/check-in', data: formData);
      return AttendanceModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}
