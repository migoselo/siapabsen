import 'location_model.dart';

class AttendanceModel {
  final int id;
  final int employeeId;
  final int locationId;
  final DateTime checkInTime;
  final double checkInLat;
  final double checkInLng;
  final double checkInDistance;
  final String checkInPhoto;
  final DateTime? checkOutTime; // BARU — dibutuhkan buat Presensi Terakhir & durasi kerja
  final String status;
  final LocationModel? location;

  AttendanceModel({
    required this.id,
    required this.employeeId,
    required this.locationId,
    required this.checkInTime,
    required this.checkInLat,
    required this.checkInLng,
    required this.checkInDistance,
    required this.checkInPhoto,
    this.checkOutTime,
    required this.status,
    this.location,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: _toInt(json['id']),
      employeeId: _toInt(json['employee_id']),
      locationId: _toInt(json['location_id']),
        checkInTime:
          (DateTime.tryParse(json['check_in_time']?.toString() ?? '')
              ?? DateTime.now())
            .toLocal(),
      checkInLat: _toDouble(json['check_in_lat']),
      checkInLng: _toDouble(json['check_in_lng']),
      checkInDistance: _toDouble(json['check_in_distance']),
      checkInPhoto: json['check_in_photo']?.toString() ?? '',
        checkOutTime: json['check_out_time'] != null
          ? DateTime.tryParse(json['check_out_time'].toString())?.toLocal()
          : null,
      status: json['status']?.toString() ?? 'pending',
      location: json['location'] != null
          ? LocationModel.fromJson(json['location'])
          : null,
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? 0;
    }
    return 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}