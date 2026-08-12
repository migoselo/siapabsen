import 'dart:io';

import '../../attendance/repository/attendance_repository.dart';
import '../../attendance/models/attendance_model.dart';

class HomeRepository {
  final AttendanceRepository _attendanceRepository;

  HomeRepository({required AttendanceRepository attendanceRepository})
      : _attendanceRepository = attendanceRepository;

  Future<AttendanceModel?> getTodayAttendance() {
    return _attendanceRepository.getTodayAttendance();
  }

  Future<List<AttendanceModel>> getHistory() {
    return _attendanceRepository.getHistory();
  }

  Future<AttendanceModel> checkOut({
    required int attendanceId,
    required double lat,
    required double lng,
    File? photo,
  }) {
    return _attendanceRepository.checkOut(
      attendanceId: attendanceId,
      lat: lat,
      lng: lng,
      photo: photo,
    );
  }
}