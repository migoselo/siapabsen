import 'package:flutter/material.dart';
import 'package:upsend_karyawan/core/widgets/kategori_bar_chart.dart';
import 'package:upsend_karyawan/features/izin/models/cuti_model.dart';

const List<KategoriChartItem> kategoriCutiList = [
  KategoriChartItem('cuti', 'Cuti', Color(0xFF14B8C4)),
  KategoriChartItem('sakit', 'Sakit', Color(0xFFF5A623)),
  KategoriChartItem('penting', 'Khusus', Color(0xFFEF4444)),
];

Map<String, int> hitungKategoriCuti(List<CutiModel> records) {
  return {
    for (final k in kategoriCutiList)
      k.key: records
          .where((r) => r.title.toLowerCase().contains(k.key))
          .length,
  };
}

// Cek apakah rentang tanggal cuti bersinggungan dengan rentang periode yang dipilih
bool cutiOverlapsPeriode(CutiModel cuti, DateTime start, DateTime end) {
  return !cuti.endDate.isBefore(start) && !cuti.startDate.isAfter(end);
}