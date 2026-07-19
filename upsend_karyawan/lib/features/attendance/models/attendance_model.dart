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
    required this.status,
    this.location,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] ?? 0,
      employeeId: json['employee_id'] ?? 0,
      locationId: json['location_id'] ?? 0,
      checkInTime: DateTime.parse(
        json['check_in_time'] ?? DateTime.now().toIso8601String(),
      ),
      checkInLat: (json['check_in_lat'] as num?)?.toDouble() ?? 0.0,
      checkInLng: (json['check_in_lng'] as num?)?.toDouble() ?? 0.0,
      checkInDistance: (json['check_in_distance'] as num?)?.toDouble() ?? 0.0,
      checkInPhoto: json['check_in_photo'] ?? '',
      status: json['status'] ?? 'pending',
      location: json['location'] != null
          ? LocationModel.fromJson(json['location'])
          : null,
    );
  }
}
