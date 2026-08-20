import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/api/api.dart';
import '../../../../core/widgets/custom_bottom_navbar.dart';
import '../../../attendance/pages/checkin_location_page.dart';
import '../../models/cuti_model.dart';
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
  bool _isFilterActive = false;

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
          'Formulir',
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
            'Pengajuan',
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
            const SizedBox(height: 80), // Space agar tidak tertutup FAB
          ],
        ),
      ),
    );
  }

  Future<void> _openDetailCuti(BuildContext context, CutiModel cuti) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailPermohonanPage(cuti: cuti)),
    );
    if (result is int && mounted) {
      final deleteRequest = Api.dio.delete('/leave-requests/$result');
      setState(() {
        _cutiHistory.removeWhere((item) => item.id == result);
      });

      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (context) => Dialog(
          child: Builder(
            builder: (dialogContext) {
              Future<void>.delayed(const Duration(seconds: 2), () {
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              });
              return Padding(
                padding: const EdgeInsets.fromLTRB(26, 30, 26, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4DBA61),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Permohonan Terhapus',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Permohonan Anda berhasil terhapus',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        color: const Color(0xFF9A9A9A),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 30),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );

      try {
        await deleteRequest;
        await _loadCutiHistory();
      } on DioException catch (error) {
        if (!mounted) return;
        await _loadCutiHistory();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.response?.data?['message']?.toString() ??
                  'Gagal menghapus permohonan.',
            ),
          ),
        );
      }
    }
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF9A9A9A),
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
