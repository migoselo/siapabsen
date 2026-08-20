import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:upsend_karyawan/core/widgets/kategori_bar_chart.dart';
import 'package:upsend_karyawan/core/widgets/riwayat_calendar_dialog.dart';
import 'package:upsend_karyawan/core/widgets/riwayat_periode_toggle.dart';
import 'package:upsend_karyawan/core/widgets/riwayat_periode_strip.dart';
import 'package:upsend_karyawan/features/izin/kategori_cuti.dart';
import 'package:upsend_karyawan/features/izin/models/cuti_model.dart';

import '../../../../core/api/api.dart';
import '../../../../core/widgets/custom_bottom_navbar.dart';
import '../../../attendance/pages/checkin_location_page.dart';
import 'detail_cuti_screen.dart';
import 'pengajuan_cuti_screen.dart';

class RiwayatCutiScreen extends StatefulWidget {
  final bool showBottomNav;
  final bool showBackButton;

  const RiwayatCutiScreen({
    super.key,
    this.showBottomNav = true,
    this.showBackButton = true,
  });

  @override
  State<RiwayatCutiScreen> createState() => _RiwayatCutiScreenState();
}

class _RiwayatCutiScreenState extends State<RiwayatCutiScreen> {
  DateTime? _selectedDate;
  DateTimeRange? _selectedRange; // BARU — nampung hasil pick range dari kalender
  String? _selectedKategori;
  PeriodeRiwayat _periode = PeriodeRiwayat.mingguan;

  final DateTime _today = DateTime.now();
  List<CutiModel> _cutiHistory = [];

  @override
  void initState() {
    super.initState();
    _loadCutiHistory();
  }

  Future<void> _loadCutiHistory() async {
    try {
      final response = await Api.dio.get('/leave-requests');
      final data = response.data as List;
      setState(() {
        _cutiHistory = data.map((json) => CutiModel.fromJson(json)).toList();
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _cutiHistory = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.response?.data['message'] ?? 'Gagal memuat riwayat cuti.',
          ),
        ),
      );
    }
  }

  Future<void> _openPengajuanCuti() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PengajuanCutiScreen()),
    );
    if (result == true) {
      await _loadCutiHistory();
    }
  }

  // Rentang tanggal yang lagi aktif — dari pick range manual (prioritas),
  // atau dihitung dari periode toggle kalau nggak ada range manual
  DateTimeRange get _activeRange {
    if (_selectedRange != null) return _selectedRange!;

    final anchor = _selectedDate ?? _today;
    switch (_periode) {
      case PeriodeRiwayat.mingguan:
        final start = anchor.subtract(Duration(days: anchor.weekday - 1));
        return DateTimeRange(start: start, end: start.add(const Duration(days: 6)));
      case PeriodeRiwayat.bulanan:
        final start = DateTime(anchor.year, anchor.month, 1);
        final end = DateTime(anchor.year, anchor.month + 1, 0);
        return DateTimeRange(start: start, end: end);
      case PeriodeRiwayat.tahunan:
        return DateTimeRange(
          start: DateTime(anchor.year, 1, 1),
          end: DateTime(anchor.year, 12, 31),
        );
    }
  }

  void _onPeriodeChanged(PeriodeRiwayat periode) {
    if (_periode == periode) return;
    setState(() {
      _periode = periode;
      _selectedDate = _today;
      _selectedRange = null; // reset range manual tiap ganti toggle
      _selectedKategori = null;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final selection = await showDialog<RiwayatCalendarSelection>(
      context: context,
      builder: (context) => RiwayatCalendarDialog(
        initialDate: _selectedDate ?? _today,
        initialRange: _selectedRange,
        today: _today,
      ),
    );

    if (selection == null) return;

    setState(() {
      switch (selection.mode) {
        case RiwayatCalendarMode.year:
          _periode = PeriodeRiwayat.tahunan;
          _selectedDate = selection.date;
          _selectedRange = null;
          break;
        case RiwayatCalendarMode.month:
          _periode = PeriodeRiwayat.bulanan;
          _selectedDate = selection.date;
          _selectedRange = null;
          break;
        case RiwayatCalendarMode.range:
          _selectedDate = selection.date;
          _selectedRange = selection.range; // ini kuncinya — akhirnya ketampung
          break;
      }
      _selectedKategori = null;
    });
  }

  String get _currentHeader {
    if (_selectedRange != null) {
      final start = _selectedRange!.start;
      final end = _selectedRange!.end;
      final sameMonth = start.month == end.month && start.year == end.year;
      if (sameMonth) {
        return '${DateFormat('d', 'id_ID').format(start)} - '
            '${DateFormat('d MMMM yyyy', 'id_ID').format(end)}';
      }
      return '${DateFormat('d MMM', 'id_ID').format(start)} - '
          '${DateFormat('d MMM yyyy', 'id_ID').format(end)}';
    }
    final currentDate = _selectedDate ?? _today;
    return _periode == PeriodeRiwayat.tahunan
        ? DateFormat('yyyy', 'id_ID').format(currentDate)
        : DateFormat('MMMM yyyy', 'id_ID').format(currentDate);
  }

  @override
  Widget build(BuildContext context) {
    final range = _activeRange;

    // filter tahap 1: berdasarkan rentang tanggal aktif (periode atau range manual)
    final rangeFiltered = _cutiHistory
        .where((cuti) => cutiOverlapsPeriode(cuti, range.start, range.end))
        .toList();

    // filter tahap 2: berdasarkan kategori yang dipilih (kalau ada)
    final filteredCuti = _selectedKategori == null
        ? rangeFiltered
        : rangeFiltered
              .where(
                (cuti) => cuti.title.toLowerCase().contains(
                  _selectedKategori!.toLowerCase(),
                ),
              )
              .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.popUntil(context, ModalRoute.withName('/home'));
                  } else {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (route) => false,
                    );
                  }
                },
              )
            : null,
        title: Text(
          'Izin Cuti',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 22,
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
      bottomNavigationBar: widget.showBottomNav
          ? CustomBottomNavBar(
              currentIndex: 1,
              onTap: (index) async {
                if (index == 1) return;

                if (index == 2) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CheckinLocationPage(),
                    ),
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                } else if (index == 3) {
                  await Navigator.pushNamed(context, '/riwayat');
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                } else if (index == 4) {
                  await Navigator.pushNamed(context, '/profile');
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                } else {
                  if (Navigator.canPop(context)) {
                    Navigator.popUntil(context, ModalRoute.withName('/home'));
                  } else {
                    await Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (route) => false,
                    );
                  }
                }
              },
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _currentHeader,
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

            RiwayatPeriodeToggle(
              selected: _periode,
              onChanged: _onPeriodeChanged,
            ),
            const SizedBox(height: 16),

            // Kalau lagi pakai range manual, kasih tombol buat balik ke mode periode
            if (_selectedRange != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRange = null;
                      _selectedDate = _today;
                    });
                  },
                  child: Row(
                    children: [
                      Icon(Icons.close, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Hapus filter rentang tanggal',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (_selectedRange == null) ...[
              RiwayatPeriodeStrip(
                periode: _periode,
                anchorDate: _selectedDate ?? _today,
                today: _today,
                onSelected: (date) {
                  setState(() {
                    _selectedDate = date;
                  });
                },
              ),
              const SizedBox(height: 16),
            ],

            KategoriBarChart(
              title: 'Kategori Cuti',
              kategoriList: kategoriCutiList,
              counts: hitungKategoriCuti(rangeFiltered), // sekarang ikut rentang aktif
              selectedKategori: _selectedKategori,
              onKategoriTap: (key) {
                setState(() => _selectedKategori = key);
              },
            ),
            const SizedBox(height: 20),

            if (filteredCuti.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  _cutiHistory.isEmpty
                      ? 'Belum ada riwayat cuti. Ajukan cuti untuk melihat progres di sini.'
                      : 'Tidak ada cuti untuk rentang/kategori ini.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              )
            else
              ...filteredCuti.map((cuti) {
                return GestureDetector(
                  onTap: () => _openDetailCuti(context, cuti),
                  child: _buildCutiCard(
                    svgPath: cuti.svgPath,
                    iconBgColor: cuti.iconBgColor,
                    title: cuti.title,
                    subtitle: cuti.subtitle,
                    statusText: cuti.statusText,
                    statusColor: cuti.statusColor,
                    statusTextColor: cuti.statusTextColor,
                    dateRange: cuti.dateRange,
                    duration: cuti.duration,
                  ),
                );
              }),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Future<void> _openDetailCuti(BuildContext context, CutiModel cuti) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailPermohonanPage(cuti: cuti)),
    );
  }

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