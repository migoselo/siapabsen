class LocationModel {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final double distance;
  final int radiusMeter;
  final bool withinRadius;
  final String workStartTime;
  final String workEndTime;

  LocationModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.distance,
    required this.radiusMeter,
    required this.withinRadius,
    required this.workStartTime,
    required this.workEndTime,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      distance: _toDouble(json['distance']),
      radiusMeter: _toInt(json['radius_meter']),
      withinRadius:
          json['within_radius'] == true ||
          json['within_radius'] == 1 ||
          json['within_radius'] == '1',
      workStartTime: json['work_start_time']?.toString() ?? '',
      workEndTime: json['work_end_time']?.toString() ?? '',
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
