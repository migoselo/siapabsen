import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/cuti_model.dart';

const Color kNavy = Color(0xFF2E3A6E);
const Color kTextPrimary = Color(0xFF0F172A);
const Color kTextSecondary = Color(0xFF6B7280);
const Color kBorder = Color(0xFFE5E7EB);
const Color kMaroon = Color(0xFF7A1F1F);
const Color kGreenBg = Color(0xFFE6F7ED);
const Color kGreenText = Color(0xFF27AE60);

/// Data status history — ini DUMMY, nanti kalau backend udah jelas,
/// list ini diganti hasil fetch dari API (kemungkinan besar endpoint
/// terpisah atau embedded di response detail cuti).
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

  // TODO: DUMMY — ganti dengan data asli dari backend begitu endpoint-nya jelas.
  static const _submittedAt = '23 Juli 2026 • 09:15';
  static const _startDate = '24 Juli 2026';
  static const _endDate = '27 Juli 2026';
  static const _reason =
      'Menikah dengan Ryul. Mohon izin cuti untuk keperluan pernikahan dan '
      'acara adat yang berlangsung di kampung halaman, sehingga membutuhkan '
      'waktu tambahan untuk persiapan dan pelaksanaan acara.';
  static const _statusHistory = [
    _StatusHistoryItem(
      title: 'Permohonan Disetujui',
      dateTime: '23 Juli 2026, 17:05',
      subtitle: 'Permohonan Anda sudah disetujui',
    ),
    _StatusHistoryItem(
      title: 'Menunggu Persetujuan',
      dateTime: '23 Juli 2026, 17:00',
      subtitle: 'Permohonan Anda sedang dalam antrean',
    ),
    _StatusHistoryItem(
      title: 'Permohonan Diajukan',
      dateTime: '23 Juli 2026, 09:10',
      subtitle: 'Data permohonan berhasil dikirim ke sistem',
    ),
  ];

  Future<void> _handleBatalkan(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Batalkan Pengajuan?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: Text(
          'Pengajuan cuti ini akan dihapus secara permanen. Apakah kamu yakin?',
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: GoogleFonts.plusJakartaSans(color: kTextSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Ya, Batalkan', style: GoogleFonts.plusJakartaSans(color: kMaroon, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // TODO: BELUM TERSAMBUNG KE BACKEND — di sini nanti manggil
    // repository.cancelCuti(cuti.id) atau semacamnya, baru setelah
    // sukses, pop halaman ini dan kasih tau RiwayatCutiScreen buat
    // hapus item dari list-nya juga.
    if (context.mounted) {
      Navigator.pop(context, 'cancelled'); // sinyal ke halaman sebelumnya
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: kGreenBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      cuti.statusText,
                      style: GoogleFonts.plusJakartaSans(
                        color: kGreenText,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Diajukan pada $_submittedAt',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kTextSecondary),
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
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kTextSecondary),
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
                        decoration: const BoxDecoration(color: kNavy, shape: BoxShape.circle),
                        child: const Icon(Icons.calendar_today, color: Colors.white, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, color: kTextPrimary),
                      children: [
                        TextSpan(text: cuti.duration.split(' ').first),
                        TextSpan(
                          text: '  ${cuti.duration.split(' ').skip(1).join(' ')}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: kTextSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- Periode cuti ---
            Text('Periode Cuti', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: kTextSecondary)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: kBorder),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _PeriodRow(label: 'MULAI', date: _startDate),
                  const Divider(height: 1, color: kBorder),
                  _PeriodRow(label: 'SELESAI', date: _endDate),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- Alasan cuti (scrollable kalau teks panjang) ---
            Text('Alasan Cuti', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: kTextSecondary)),
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
                  _reason,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: kTextPrimary, height: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- Riwayat status (timeline) ---
            Text('Riwayat Status', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: kTextSecondary)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  'Batalkan Pengajuan',
                  style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
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
          const Icon(Icons.calendar_today_outlined, size: 16, color: kTextSecondary),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: kTextSecondary)),
              const SizedBox(height: 2),
              Text(date, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: kTextPrimary)),
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
                decoration: const BoxDecoration(color: kNavy, shape: BoxShape.circle),
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
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: kTextPrimary),
                        ),
                      ),
                      Text(
                        item.dateTime,
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: kTextSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kTextSecondary),
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