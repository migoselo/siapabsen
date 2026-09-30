import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final int id;
  final String name;
  final String email;
  final String noHp;
  final String role;
  final String? employeeId;
  final int? homeLocationId;
  final String? homeLocationName;
  final int? divisionId;
  final String? divisionName;
  final int? shiftId;
  final String? shiftName;
  final String? shiftWorkStartTime;
  final String? shiftWorkEndTime;
  final bool isActive;
  final Map<String, dynamic> biodata;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.noHp,
    required this.role,
    this.employeeId,
    this.homeLocationId,
    this.homeLocationName,
    this.divisionId,
    this.divisionName,
    this.shiftId,
    this.shiftName,
    this.shiftWorkStartTime,
    this.shiftWorkEndTime,
    required this.isActive,
    this.biodata = const {},
  });

  String get employeeCode => employeeId ?? '-';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final homeLocation = json['home_location'];
    final division = json['division'];
    final shift = json['shift'];

    return UserModel(
      id: _parseInt(json['id']) ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      noHp: json['no_hp'] ?? '',
      role: json['role'] ?? '',
      employeeId: json['employee_id']?.toString(),
      homeLocationId: _parseInt(json['home_location_id']),
      homeLocationName:
          _relationField(homeLocation, 'name') ??
          json['home_location_name']?.toString(),
      divisionId: _parseInt(
        json['division_id'] ?? _relationField(division, 'id'),
      ),
      divisionName:
          _relationField(division, 'name') ?? json['division_name']?.toString(),
      shiftId: _parseInt(json['shift_id'] ?? _relationField(shift, 'id')),
      shiftName:
          _relationField(shift, 'name') ?? json['shift_name']?.toString(),
      shiftWorkStartTime:
          _relationField(shift, 'work_start_time') ??
          json['shift_work_start_time']?.toString(),
      shiftWorkEndTime:
          _relationField(shift, 'work_end_time') ??
          json['shift_work_end_time']?.toString(),
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

  String get shiftDisplayName {
    if (shiftName == null || shiftName!.isEmpty) return 'Gunakan jam lokasi';
    final start = _formatTime(shiftWorkStartTime);
    final end = _formatTime(shiftWorkEndTime);
    return start.isNotEmpty && end.isNotEmpty
        ? '$shiftName ($start - $end)'
        : shiftName!;
  }

  static String _formatTime(String? value) {
    if (value == null || value.isEmpty) return '';
    return value.length >= 5 ? value.substring(0, 5) : value;
  }

  static String? _relationField(dynamic relation, String key) {
    if (relation is Map) return relation[key]?.toString();
    return null;
  }

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
    employeeId,
    homeLocationId,
    homeLocationName,
    divisionId,
    divisionName,
    shiftId,
    shiftName,
    shiftWorkStartTime,
    shiftWorkEndTime,
    isActive,
    biodata,
  ];
}
