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
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      noHp: json['no_hp'] ?? '',
      role: json['role'] ?? '',
      homeLocationId: json['home_location_id'],
      isActive: json['is_active'] ?? false,
    );
  }
}