import 'package:flutter/material.dart';

class CutiModel {
  final String svgPath;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final String statusText;
  final Color statusColor;
  final Color statusTextColor;
  final String dateRange;
  final String duration;

  CutiModel({
    required this.svgPath,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.statusText,
    required this.statusColor,
    required this.statusTextColor,
    required this.dateRange,
    required this.duration,
  });
}
