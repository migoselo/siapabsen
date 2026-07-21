class LocationModel {
  final int id;
  final String name;
  final double distance;
  final int radiusMeter;
  final bool withinRadius;

  LocationModel({
    required this.id,
    required this.name,
    required this.distance,
    required this.radiusMeter,
    required this.withinRadius,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      distance: _toDouble(json['distance']),
      radiusMeter: _toInt(json['radius_meter']),
      withinRadius:
          json['within_radius'] == true ||
          json['within_radius'] == 1 ||
          json['within_radius'] == '1',
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String)
      return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? 0;
    return 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
