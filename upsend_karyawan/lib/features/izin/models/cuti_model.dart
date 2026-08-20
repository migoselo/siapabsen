import 'package:flutter/material.dart';

class CutiModel {
  final int? id;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? createdAt;
  final String reason;
  final String status;
  final String? svgPath;
  final IconData? iconData;
  final Color iconBgColor;
  final Color iconColor;
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
    this.svgPath,
    this.iconData,
    required this.iconBgColor,
    required this.iconColor,
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
    var startDate =
        DateTime.tryParse(json['start_date']?.toString() ?? '') ??
        DateTime.now();
    var endDate =
        DateTime.tryParse(json['end_date']?.toString() ?? '') ?? startDate;

    startDate = _mergeTime(startDate, json['start_time']?.toString());
    endDate = _mergeTime(endDate, json['end_time']?.toString());
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
      svgPath: _svgForType(type),
      iconData: _iconDataForType(type),
      iconBgColor: _bgForType(type),
      iconColor: _colorForType(type),
      title: type,
      subtitle: (json['reason'] ?? '').toString(),
      statusText: _statusText(status),
      statusColor: _statusColor(status),
      statusTextColor: _statusTextColor(status),
      dateRange: '${_formatDate(startDate)} - ${_formatDate(endDate)}',
      duration: _formatDuration(type, startDate, endDate, durationDays),
        attachmentUrl: json['attachment_url']?.toString() ??
          json['attachment_path']?.toString() ??
          json['attachment']?.toString(),
        attachmentName: json['attachment_name']?.toString() ??
          _attachmentName(json['attachment_path']?.toString()),
    );
  }

  static String? _nullableString(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')} ${_month(date.month)} ${date.year}';
  }

  static String? _attachmentName(String? path) {
    if (path == null || path.isEmpty) return null;
    return path.split('/').last;
  }

  static DateTime _mergeTime(DateTime date, String? timeStr) {
    if (timeStr == null || !timeStr.contains(':')) return date;
    final parts = timeStr.split(':');
    final hour = int.tryParse(parts[0]) ?? date.hour;
    final minute =
        int.tryParse(parts.length > 1 ? parts[1] : '0') ?? date.minute;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  static String _formatDuration(
    String type,
    DateTime start,
    DateTime end,
    int durationDays,
  ) {
    if (type.toLowerCase().contains('lembur')) {
      final total = end.difference(start);
      final jam = total.inHours;
      final menit = total.inMinutes % 60;

      if (jam <= 0 && menit <= 0) return '0 Menit';
      if (jam == 0) return '$menit Menit';
      if (menit == 0) return '$jam Jam';
      return '$jam Jam $menit Menit';
    }
    return '$durationDays Hari';
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

  static String? _svgForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('izin') || t.contains('lembur')) return null;

    if (t.contains('sakit')) return 'assets/images/Medical.svg';
    if (t.contains('penting') || t.contains('khusus')) {
      return 'assets/images/seru.svg';
    }
    return 'assets/images/Calendar.svg'; // Cuti Tahunan & default
  }

  static IconData? _iconDataForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('izin')) return Icons.assignment;
    if (t.contains('lembur')) return Icons.timer;
    return null; // kategori Cuti -> pakai svgPath
  }

  static Color _bgForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('izin')) return const Color(0xFFE3F5EA); // hijau muda
    if (t.contains('lembur')) return const Color(0xFFF3E8FF); // ungu muda
    return const Color(0xFFE8EEFF); // biru muda (kategori Cuti)
  }

  static Color _colorForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('izin')) return const Color(0xFF1DB677); // hijau
    if (t.contains('lembur')) return const Color(0xFF85409D); // ungu
    return const Color(0xFF2E3A6E); // navy (kategori Cuti)
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
