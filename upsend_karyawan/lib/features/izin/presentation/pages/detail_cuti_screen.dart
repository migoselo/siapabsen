import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dio/dio.dart';
import '../../../../core/api/api.dart';
import '../../models/cuti_model.dart';

const Color kNavy = Color(0xFF2E3A6E);
const Color kTextPrimary = Color(0xFF000000);
const Color kTextSecondary = Color(0xFF9A9A9A);
const Color kBorder = Color(0xFFE5E7EB);
const Color kMaroon = Color(0xFF7A1F1F);

class _StatusHistoryItem {
  final String title;
  final String dateTime;
  final String subtitle;
  const _StatusHistoryItem({
    required this.title,
    required this.dateTime,
    required this.subtitle,
  });
}

class DetailPermohonanPage extends StatelessWidget {
  final CutiModel cuti;
  const DetailPermohonanPage({super.key, required this.cuti});

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')} ${_months[date.month - 1]} ${date.year}';

  String _formatDateTime(DateTime? date) {
    if (date == null) return '-';
    return '${_formatDate(date)}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  List<_StatusHistoryItem> get _statusHistory {
    final submittedAt = _formatDateTime(cuti.createdAt);
    final items = [
      _StatusHistoryItem(
        title: 'Permohonan Diajukan',
        dateTime: submittedAt,
        subtitle: 'Data permohonan berhasil dikirim ke sistem',
      ),
    ];
    if (cuti.status.toLowerCase() != 'pending') {
      final approved = cuti.status.toLowerCase() == 'approved';
      items.insert(
        0,
        _StatusHistoryItem(
          title: approved ? 'Permohonan Disetujui' : 'Permohonan Ditolak',
          dateTime: _formatDateTime(cuti.createdAt),
          subtitle: approved
              ? 'Permohonan Anda sudah disetujui'
              : 'Permohonan Anda ditolak',
        ),
      );
    } else {
      items.insert(
        0,
        _StatusHistoryItem(
          title: 'Menunggu Persetujuan',
          dateTime: submittedAt,
          subtitle: 'Permohonan Anda sedang dalam antrean',
        ),
      );
    }
    return items;
  }

  static const _months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  Future<void> _handleBatalkan(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Batalkan Pengajuan?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Pengajuan cuti ini akan dihapus secara permanen. Apakah kamu yakin?',
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Batal',
              style: GoogleFonts.plusJakartaSans(color: kTextSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Ya, Batalkan',
              style: GoogleFonts.plusJakartaSans(
                color: kMaroon,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (cuti.id == null) return;

    try {
      await Api.dio.delete('/leave-requests/${cuti.id}');
      if (context.mounted) Navigator.pop(context, 'cancelled');
    } on DioException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.response?.data?['message']?.toString() ??
                'Gagal membatalkan pengajuan.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Detail Permohonan',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Status + tanggal diajukan ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: kBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cuti.statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      cuti.statusText,
                      style: GoogleFonts.plusJakartaSans(
                        color: cuti.statusTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Diajukan pada ${_formatDateTime(cuti.createdAt)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: kTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- Tipe cuti + durasi ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: kBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tipe Cuti',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: kTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cuti.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: kNavy,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: kNavy,
                          shape: BoxShape.circle,
                        ),
                        child: SvgPicture.asset(
                          'assets/images/Calender_white.svg',
                          width: 14,
                          height: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: kTextPrimary,
                      ),
                      children: [
                        TextSpan(text: cuti.duration.split(' ').first),
                        TextSpan(
                          text:
                              '  ${cuti.duration.split(' ').skip(1).join(' ')}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: kTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- Periode cuti ---
            Text(
              'Periode Cuti',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kTextSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: kBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _PeriodRow(label: 'MULAI', date: _formatDate(cuti.startDate)),
                  const Divider(height: 1, color: kBorder),
                  _PeriodRow(label: 'SELESAI', date: _formatDate(cuti.endDate)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- Alasan cuti (scrollable kalau teks panjang) ---
            Text(
              'Alasan Cuti',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kTextSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              height: 140,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: kBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: Text(
                  cuti.reason,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: kTextPrimary,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- Riwayat status (timeline) ---
            Text(
              'Riwayat Status',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kTextSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: kBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: List.generate(_statusHistory.length, (i) {
                  final item = _statusHistory[i];
                  final isLast = i == _statusHistory.length - 1;
                  return _TimelineItem(item: item, isLast: isLast);
                }),
              ),
            ),
            const SizedBox(height: 28),

            // --- Tombol batalkan ---
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => _handleBatalkan(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kMaroon,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Batalkan Pengajuan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _PeriodRow extends StatelessWidget {
  final String label;
  final String date;

  const _PeriodRow({required this.label, required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 16,
            color: kTextSecondary,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: kTextSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                date,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final _StatusHistoryItem item;
  final bool isLast;

  const _TimelineItem({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: kNavy,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              ),
              if (!isLast) Expanded(child: Container(width: 2, color: kBorder)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: kTextPrimary,
                          ),
                        ),
                      ),
                      Text(
                        item.dateTime,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: kTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: kTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
