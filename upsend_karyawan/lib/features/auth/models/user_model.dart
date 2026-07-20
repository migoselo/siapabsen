class UserModel {
  final int id;
  final String name;
  final String email;
  final String noHp;
  final String role;
  final int? homeLocationId;
  final bool isActive;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.noHp,
    required this.role,
    this.homeLocationId,
    required this.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: _parseInt(json['id']) ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      noHp: json['no_hp'] ?? '',
      role: json['role'] ?? '',
      homeLocationId: _parseInt(json['home_location_id']),
      isActive: json['is_active'] ?? false,
    );
  }

  // Backend kadang ngirim angka sebagai String (misal "1" bukan 1),
  // fungsi ini handle baik format int maupun String.
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}
