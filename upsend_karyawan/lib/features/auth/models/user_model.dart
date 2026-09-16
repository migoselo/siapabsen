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
  final Map<String, dynamic> biodata;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.noHp,
    required this.role,
    this.homeLocationId,
    this.homeLocationName,
    required this.isActive,
    this.biodata = const {},
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
      homeLocationName: homeLocation != null
          ? homeLocation['name']?.toString()
          : null,
      isActive: json['is_active'] ?? false,
      biodata: {
        for (final key in _biodataKeys)
          if (json[key] != null) key: json[key],
      },
    );
  }

  static const _biodataKeys = [
    'department',
    'grade',
    'employee_type',
    'joined_at',
    'nik',
    'birth_place',
    'birth_date',
    'gender',
    'religion',
    'blood_type',
    'marital_status',
    'address',
    'emergency_contact',
    'bank_name',
    'bank_account_number',
    'bank_account_name',
    'tax_number',
    'bpjs_employment',
    'bpjs_health',
    'last_education',
    'education_institution',
    'certification',
    'spouse_name',
    'father_name',
    'mother_name',
    'children_count',
  ];

  String biodataValue(String key) => biodata[key]?.toString() ?? '-';

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    noHp,
    role,
    homeLocationId,
    homeLocationName,
    isActive,
    biodata,
  ];
}
