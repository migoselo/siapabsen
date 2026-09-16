import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:dio/dio.dart';
import 'dart:typed_data';
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

  Future<void> _showAttachmentPreview(BuildContext context) async {
    final attachment = cuti.attachmentUrl;
    if (attachment == null || attachment.isEmpty) return;
    final baseUrl = Api.dio.options.baseUrl.replaceFirst('/api', '');
    final url = attachment.startsWith('http')
        ? attachment
        : '$baseUrl/${attachment.replaceFirst(RegExp(r'^/'), '')}';
    final fileName = cuti.attachmentName ?? 'Lampiran';
    final lowerName = fileName.toLowerCase();
    final isImage = ['.jpg', '.jpeg', '.png'].any(lowerName.endsWith);
    final isPdf = lowerName.endsWith('.pdf');
    Uint8List? fileBytes;

    if (isImage || isPdf) {
      try {
        final response = await Api.dio.get<List<int>>(
          url,
          options: Options(responseType: ResponseType.bytes),
        );
        if (response.data != null) {
          fileBytes = Uint8List.fromList(response.data!);
        }
      } on DioException {
        fileBytes = null;
      }
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: isImage ? Colors.black : Colors.white,
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width,
          height: MediaQuery.sizeOf(context).height,
          child: SafeArea(
            child: Stack(
              children: [
            if (isImage)
              Center(
                child: fileBytes == null
                    ? const Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.white,
                        size: 42,
                      )
                    : InteractiveViewer(
                        child: Image.memory(fileBytes!, fit: BoxFit.contain),
                      ),
              )
            else if (isPdf)
              fileBytes == null
                  ? const Center(
                      child: Text('Lampiran PDF tidak tersedia'),
                    )
                  : SfPdfViewer.memory(fileBytes!)
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.insert_drive_file,
                        color: kNavy,
                        size: 72,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        fileName,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Format lampiran belum mendukung preview isi',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: kTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: () => Navigator.pop(dialogContext),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isImage
                        ? Colors.black.withValues(alpha: 0.6)
                        : Colors.grey.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: isImage ? Colors.white : kTextPrimary,
                    size: 20,
                  ),
                ),
              ),
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')} ${_months[date.month - 1]} ${date.year}';

  String _formatDateTime(DateTime? date) {
    if (date == null) return '-';
    final local = date.toLocal();
    return '${_formatDate(local)}, ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

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
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 34, 26, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_rounded, color: Colors.red, size: 48),
              const SizedBox(height: 14),
              Text(
                'Hapus Permohonan?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Anda akan menghapus permohonan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  color: kTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 51,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFE0E0E0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Batal',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF536878),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: SizedBox(
                      height: 51,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFFED0B0B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Hapus',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;

    if (cuti.id == null) return;
    Navigator.pop(context, cuti.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detail Permohonan',
          style: GoogleFonts.plusJakartaSans(
            color: kTextPrimary,
            fontWeight: FontWeight.w600,
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
                      fontWeight: FontWeight.w600,
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
                                fontWeight: FontWeight.w600,
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
                      ClipOval(
                        child: Container(
                          width: 40,
                          height: 40,
                          color: kNavy,
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: SvgPicture.asset(
                                'assets/images/Calender_white.svg',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
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
                            color: kTextPrimary,
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
              cuti.title.toLowerCase().contains('lembur')
                  ? 'Waktu Lembur'
                  : 'Periode',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: kTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: kBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: cuti.title.toLowerCase().contains('lembur')
                  ? Column(
                      children: [
                        _PeriodRow(
                          label: 'MULAI',
                          date: _formatTime(cuti.startDate),
                        ),
                        const Divider(height: 1, color: kBorder),
                        _PeriodRow(
                          label: 'SELESAI',
                          date: _formatTime(cuti.endDate),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _PeriodRow(
                          label: 'MULAI',
                          date: _formatDate(cuti.startDate),
                        ),
                        const Divider(height: 1, color: kBorder),
                        _PeriodRow(
                          label: 'SELESAI',
                          date: _formatDate(cuti.endDate),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),

            // --- Alasan cuti (scrollable kalau teks panjang) ---
            Text(
              'Alasan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
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

            // --- Lampiran ---
            if (cuti.attachmentUrl != null) ...[
              Text(
                'Lampiran',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _showAttachmentPreview(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: kBorder),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: kNavy.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          (cuti.attachmentName ?? '').toLowerCase().endsWith(
                                '.pdf',
                              )
                              ? Icons.picture_as_pdf
                              : Icons.image,
                          color: kNavy,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          cuti.attachmentName ?? 'Lihat lampiran',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: kTextPrimary,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: kTextSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // --- Riwayat status (timeline) ---
            Text(
              'Riwayat Status',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
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
