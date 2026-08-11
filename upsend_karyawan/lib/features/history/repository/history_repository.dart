import '../../../core/api/api.dart';
import '../../attendance/models/attendance_model.dart';

class HistoryRepository {
  /// GET /attendances/history
  /// Backend: AttendanceController@myHistory
  /// Support query params: start_date, end_date (format: YYYY-MM-DD)
  Future<List<AttendanceModel>> getHistory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) {
        queryParams['start_date'] =
            startDate.toIso8601String().split('T').first;
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String().split('T').first;
      }

      final response = await Api.dio.get(
        '/attendances/my-history',
        queryParameters: queryParams,
      );

      // Backend pakai paginate(), datanya ada di key 'data'
      final List data = response.data['data'] ?? [];
      return data.map((json) => AttendanceModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }
}