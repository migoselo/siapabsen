import 'package:flutter/material.dart';
import '../../../core/widgets/kategori_bar_chart.dart';
import '../../attendance/models/attendance_model.dart';

const List<KategoriChartItem> kategoriPresensiList = [
  KategoriChartItem('semua', 'Semua', Color(0xFF7D7C7C)),
  KategoriChartItem('tepat_waktu', 'Tepat', Color(0xFF1FAE7C)),
  KategoriChartItem('telat', 'Telat', Color(0xFFF5A623)),
  KategoriChartItem('lupa_absen', 'Lupa', Color(0xFF0284C7)),
  KategoriChartItem('alpha', 'Alpha', Color(0xFFEF4444)),
  KategoriChartItem('lembur', 'Lembur', Color(0xFF7C3AED)),
];

Map<String, int> hitungKategoriPresensi(List<AttendanceModel> records) {
  return {
    'semua': records.length,
    for (final k in kategoriPresensiList.where((k) => k.key != 'semua'))
      k.key: records.where((r) => r.status.toLowerCase() == k.key).length,
  };
}
