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
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      distance: (json['distance'] as num).toDouble(),
      radiusMeter: json['radius_meter'] ?? 0,
      withinRadius: json['within_radius'] ?? false,
    );
  }
}
