import 'package:flutter/material.dart';
import 'package:upsend_karyawan/core/widgets/kategori_bar_chart.dart';
import 'package:upsend_karyawan/features/izin/models/cuti_model.dart';

const List<KategoriChartItem> kategoriCutiList = [
  KategoriChartItem('semua', 'Semua', Color(0xFFF4B752)),
  KategoriChartItem('cuti', 'Cuti', Color(0xFF2E3A6E)),
  KategoriChartItem('izin', 'Izin', Color(0xFF1DB677)),
  KategoriChartItem('lembur', 'Lembur', Color(0xFF85409D)),
];

Map<String, int> hitungKategoriCuti(List<CutiModel> records) {
  return {
    for (final k in kategoriCutiList)
      k.key: k.key == 'semua'
          ? records.length
          : records
                .where((r) => r.title.toLowerCase().contains(k.key))
                .length,
  };
}

// Cek apakah rentang tanggal cuti bersinggungan dengan rentang periode yang dipilih
bool cutiOverlapsPeriode(CutiModel cuti, DateTime start, DateTime end) {
  return !cuti.endDate.isBefore(start) && !cuti.startDate.isAfter(end);
}