import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/cuti_model.dart';

class RiwayatCutiScreen extends StatefulWidget {
  const RiwayatCutiScreen({Key? key}) : super(key: key);

  @override
  State<RiwayatCutiScreen> createState() => _RiwayatCutiScreenState();
}

class _RiwayatCutiScreenState extends State<RiwayatCutiScreen> {
  DateTime? _selectedDate;
  bool _isFilterActive = false;

  final DateTime _today = DateTime.now();

  final List<CutiModel> _cutiHistory = [
    CutiModel(
      svgPath: 'assets/images/Calendar.svg',
      iconBgColor: const Color(0xFFE8EEFF),
      title: 'Cuti Tahunan',
      subtitle: 'Liburan Akhir Tahun',
      statusText: 'DISETUJUI',
      statusColor: const Color(0xFFE6F7ED),
      statusTextColor: const Color(0xFF27AE60),
      dateRange: '24 Jul - 27 Jul 2026',
      duration: '4 Hari',
    ),
    CutiModel(
      svgPath: 'assets/images/Medical.svg',
      iconBgColor: const Color(0xFFFFF7E6),
      title: 'Cuti Sakit',
      subtitle: 'Sakit demam',
      statusText: 'DIPROSES',
      statusColor: const Color(0xFFFFF8E1),
      statusTextColor: const Color(0xFFE2B93B),
      dateRange: '24 Jul - 27 Jul 2026',
      duration: '4 Hari',
    ),
  ];

  Future<void> _openPengajuanCuti() async {
    final result = await Navigator.pushNamed(context, '/pengajuan_cuti');
    if (result is CutiModel) {
      setState(() {
        _cutiHistory.insert(0, result);
      });
    }
  }

  // Membuka DatePicker bawaan Flutter
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? _today,
      firstDate: DateTime(2020),
      lastDate: _today, // Mencegah memilih tanggal di masa depan
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF2E3A6E)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _isFilterActive = true;
      });
    }
  }

  // Menghasilkan daftar 7 hari (3 hari sebelum & 3 hari sesudah tanggal yang dipilih)
  List<DateTime> _generateDateList(DateTime centerDate) {
    return List.generate(7, (index) {
      return centerDate.add(Duration(days: index - 3));
    });
  }

  @override
  Widget build(BuildContext context) {
    final String currentMonthYear = DateFormat(
      'MMMM yyyy',
      'id_ID',
    ).format(_selectedDate ?? _today);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Riwayat Cuti',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: FloatingActionButton.extended(
          onPressed: _openPengajuanCuti,
          backgroundColor: const Color(0xFF2E3A6E),
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            'Ajukan Cuti',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bulan & Tombol Kalender
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currentMonthYear,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E1E1E),
                  ),
                ),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: SvgPicture.asset(
                    'assets/images/Calendar.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF2E3A6E),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Filter Strip Tanggal (Hanya muncul jika kalender diklik)
            if (_isFilterActive && _selectedDate != null) ...[
              SizedBox(
                height: 70,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _generateDateList(_selectedDate!).map((date) {
                    final isSameDay =
                        date.year == _selectedDate!.year &&
                        date.month == _selectedDate!.month &&
                        date.day == _selectedDate!.day;

                    // Cek apakah tanggal melebihi hari ini
                    final isFutureDate = date.isAfter(
                      DateTime(_today.year, _today.month, _today.day, 23, 59),
                    );

                    return GestureDetector(
                      onTap: isFutureDate
                          ? null
                          : () {
                              setState(() {
                                _selectedDate = date;
                              });
                            },
                      child: Container(
                        width: 55,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: isSameDay
                              ? const Color(0xFF2E3A6E)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isFutureDate
                                ? Colors.grey.shade300
                                : (isSameDay
                                      ? const Color(0xFF2E3A6E)
                                      : Colors.grey.shade300),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat(
                                'E',
                                'id_ID',
                              ).format(date), // Nama Hari
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: isFutureDate
                                    ? Colors.grey.shade400
                                    : (isSameDay
                                          ? Colors.white
                                          : Colors.grey.shade600),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              date.day.toString(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isFutureDate
                                    ? Colors.grey.shade400
                                    : (isSameDay
                                          ? Colors.white
                                          : const Color(0xFF2E3A6E)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Subtitle Tanggal Terpilih (jika aktif)
            if (_isFilterActive && _selectedDate != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  DateFormat(
                    'EEEE, d MMMM yyyy',
                    'id_ID',
                  ).format(_selectedDate!),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),

            // Daftar Kartu Cuti
            if (_cutiHistory.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Belum ada riwayat cuti. Ajukan cuti untuk melihat progres di sini.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              )
            else
              ..._cutiHistory.map((cuti) {
                return _buildCutiCard(
                  svgPath: cuti.svgPath,
                  iconBgColor: cuti.iconBgColor,
                  title: cuti.title,
                  subtitle: cuti.subtitle,
                  statusText: cuti.statusText,
                  statusColor: cuti.statusColor,
                  statusTextColor: cuti.statusTextColor,
                  dateRange: cuti.dateRange,
                  duration: cuti.duration,
                );
              }).toList(),
            const SizedBox(height: 80), // Space agar tidak tertutup FAB
          ],
        ),
      ),
    );
  }

  // Widget Reusable untuk Item Kartu Cuti
  Widget _buildCutiCard({
    required String svgPath,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required String statusText,
    required Color statusColor,
    required Color statusTextColor,
    required String dateRange,
    required String duration,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(svgPath, fit: BoxFit.contain),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.plusJakartaSans(
                    color: statusTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tanggal',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateRange,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.black,
                  ),
                  children: [
                    const TextSpan(text: 'Durasi '),
                    TextSpan(
                      text: duration,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
