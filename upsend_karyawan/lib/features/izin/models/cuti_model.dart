import 'package:flutter/material.dart';

class CutiModel {
  final int? id;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? createdAt;
  final String reason;
  final String status;
  final String svgPath;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final String statusText;
  final Color statusColor;
  final Color statusTextColor;
  final String dateRange;
  final String duration;
  final String? attachmentUrl;
  final String? attachmentName;

  CutiModel({
    this.id,
    required this.startDate,
    required this.endDate,
    this.createdAt,
    required this.reason,
    required this.status,
    required this.svgPath,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.statusText,
    required this.statusColor,
    required this.statusTextColor,
    required this.dateRange,
    required this.duration,
    this.attachmentUrl,
    this.attachmentName,
  });

  factory CutiModel.fromJson(Map<String, dynamic> json) {
    final type = (json['type'] ?? 'Cuti').toString();
    final startDate =
        DateTime.tryParse(json['start_date']?.toString() ?? '') ??
        DateTime.now();
    final endDate =
        DateTime.tryParse(json['end_date']?.toString() ?? '') ?? startDate;
    final durationDays = endDate.difference(startDate).inDays + 1;
    final status = (json['status'] ?? 'pending').toString();

    return CutiModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? ''),
      startDate: startDate,
      endDate: endDate,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      reason: (json['reason'] ?? '').toString(),
      status: status,
      svgPath: _iconForType(type),
      iconBgColor: _bgForType(type),
      title: type,
      subtitle: (json['reason'] ?? '').toString(),
      statusText: _statusText(status),
      statusColor: _statusColor(status),
      statusTextColor: _statusTextColor(status),
      dateRange: '${_formatDate(startDate)} - ${_formatDate(endDate)}',
      duration: '$durationDays Hari',
      attachmentUrl: _nullableString(json['attachment_url']),
      attachmentName: _nullableString(json['attachment_name']),
    );
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')} ${_month(date.month)} ${date.year}';
  }

  static String _month(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return months[month - 1];
  }

  static String _iconForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('sakit')) return 'assets/images/Medical.svg';
    if (t.contains('penting')) return 'assets/images/seru.svg';
    return 'assets/images/Calendar.svg';
  }

  static Color _bgForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('sakit')) return const Color(0xFFFFF7E6);
    if (t.contains('penting')) return const Color(0xFFFFEAEA);
    return const Color(0xFFE8EEFF);
  }

  static String _statusText(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'DISETUJUI';
      case 'rejected':
        return 'DITOLAK';
      default:
        return 'DIPROSES';
    }
  }

  static Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFFE6F7ED);
      case 'rejected':
        return const Color(0xFFFDECEC);
      default:
        return const Color(0xFFFFF8E1);
    }
  }

  static Color _statusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF27AE60);
      case 'rejected':
        return const Color(0xFFE74C3C);
      default:
        return const Color(0xFFE2B93B);
    }
  }
}
