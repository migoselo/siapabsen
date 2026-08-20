import 'package:flutter/material.dart';
import '../../core/widgets/kategori_bar_chart.dart';
import '../attendance/models/attendance_model.dart'; 

const List<KategoriChartItem> kategoriPresensiList = [
  KategoriChartItem('tepat_waktu', 'Tepat', Color(0xFF1FAE7C)),
  KategoriChartItem('telat', 'Telat', Color(0xFFF5A623)),
  KategoriChartItem('lupa_absen', 'Lupa', Color(0xFFEF4444)),
  KategoriChartItem('lembur', 'Lembur', Color(0xFF2F6FEB)),
];

Map<String, int> hitungKategoriPresensi(List<AttendanceModel> records) {
  return {
    for (final k in kategoriPresensiList)
      k.key: records
          .where((r) => r.status.toLowerCase() == k.key.toLowerCase())
          .length,
  };
}