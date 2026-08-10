import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final int id;
  final String name;
  final String email;
  final String noHp;
  final String role;
  final int? homeLocationId;
  final String? homeLocationName;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.noHp,
    required this.role,
    this.homeLocationId,
    this.homeLocationName,
    required this.isActive,
  });

  String get employeeCode => 'EMP-${id.toString().padLeft(4, '0')}';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final homeLocation = json['home_location'];

    return UserModel(
      id: _parseInt(json['id']) ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      noHp: json['no_hp'] ?? '',
      role: json['role'] ?? '',
      homeLocationId: _parseInt(json['home_location_id']),
      homeLocationName: homeLocation != null ? homeLocation['name']?.toString() : null,
      isActive: json['is_active'] ?? false,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  @override
  List<Object?> get props =>
      [id, name, email, noHp, role, homeLocationId, homeLocationName, isActive];
}