import 'package:flutter/material.dart';
import '../../../core/widgets/riwayat_calendar_dialog.dart';

const Color kNavy = Color(0xFF2F3B69);
const Color kNavyLight = Color(0xFF4E62AF);
const Color kTextPrimary = Color(0xFF0F172A);
const Color kTextSecondary = Color(0xFF6B7280);
const Color kBorder = Color(0xFFE5E7EB);
const Color kAccentBlue = Color(0xFF3B5BDB);
const String kFontFamily = 'PlusJakartaSans';

class SlipGajiPage extends StatefulWidget {
  const SlipGajiPage({super.key});

  @override
  State<SlipGajiPage> createState() => _SlipGajiPageState();
}

class _SlipGajiPageState extends State<SlipGajiPage> {
  DateTime _selectedMonth = DateTime.now();

  // =====================================================================
  // TODO: SEMUA DATA DI BAWAH INI DUMMY — belum ada endpoint payroll.
  // Begitu backend-nya jelas, ganti jadi fetch dari repository berdasarkan
  // _selectedMonth (kemungkinan GET /payroll?month=9&year=2026 atau serupa).
  // =====================================================================
  static const _namaBank = 'Mandiri';
  static const _akunPenerima = 'Migoselo';
  static const _gajiPokok = 4000000;
  static const _tunjangan1 = 500000;
  static const _tunjangan2 = 150000;
  static const _tunjangan3 = 350000;
  static const _pajak = 1000000;

  int get _totalPenerimaan => _gajiPokok + _tunjangan1 + _tunjangan2 + _tunjangan3;
  int get _totalPotongan => _pajak;
  int get _gajiBersih => _totalPenerimaan - _totalPotongan;

  String _formatRupiah(int value) {
    final str = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return 'Rp$buffer';
  }

  String get _monthYearText {
    const bulan = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return '${bulan[_selectedMonth.month - 1]} ${_selectedMonth.year}';
  }

  Future<void> _pickMonth() async {
    final result = await showDialog<RiwayatCalendarSelection>(
      context: context,
      builder: (context) => RiwayatCalendarDialog(
        initialDate: _selectedMonth,
        initialRange: null,
        today: DateTime.now(),
        initialMode: RiwayatCalendarMode.month, // langsung mode pilih bulan
      ),
    );

    if (result != null) {
      setState(() {
        // mode month/year balikin `date` sebagai tanggal 1 di bulan/tahun terpilih.
        // Kalau user somehow milih mode range, ambil bulan dari start-nya aja.
        _selectedMonth = result.range != null ? result.range!.start : result.date;
      });
      // TODO: panggil ulang fetch data payroll buat _selectedMonth yang baru di sini.
    }
  }

  void _downloadSlip() {
    // TODO: BELUM TERSAMBUNG — belum ada backend yang generate PDF slip gaji.
    // Kalau mau di-generate langsung di Flutter (bukan dari backend), bisa
    // pakai package `pdf` + `printing`/`path_provider`, tapi itu nambah
    // dependency baru yang belum saya konfirmasi ke kamu.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur unduh PDF belum tersambung ke backend.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // --- Header navy melengkung ---
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 28,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: kNavy,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Slip Gaji',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: kFontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 8),

                // --- Selector bulan ---
                GestureDetector(
                  onTap: _pickMonth,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: kNavyLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, color: Colors.white, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _monthYearText,
                            style: const TextStyle(
                              fontFamily: kFontFamily,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // --- Kartu gaji bersih + tombol unduh ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kNavyLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Gaji Bersih',
                            style: TextStyle(fontFamily: kFontFamily, fontSize: 14, color: Colors.white),
                          ),
                          Text(
                            _formatRupiah(_gajiBersih),
                            style: const TextStyle(
                              fontFamily: kFontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _downloadSlip,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Unduh Slip Gaji',
                            style: TextStyle(
                              fontFamily: kFontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: kNavy,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- Detail rincian ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionCard(
                    title: 'Informasi Penerima',
                    rows: [
                      ('Nama Bank', _namaBank, false),
                      ('Akun Penerima', _akunPenerima, false),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionCard(
                    title: 'Rincian Penerimaan',
                    rows: [
                      ('Gaji Pokok', _formatRupiah(_gajiPokok), false),
                      ('Tunjangan', _formatRupiah(_tunjangan1), false),
                      ('Tunjangan', _formatRupiah(_tunjangan2), false),
                      ('Tunjangan', _formatRupiah(_tunjangan3), false),
                      ('Total Penerimaan', _formatRupiah(_totalPenerimaan), true),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionCard(
                    title: 'Rincian Potongan',
                    rows: [
                      ('Pajak', _formatRupiah(_pajak), false),
                      ('Total Potongan', _formatRupiah(_totalPotongan), true),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionCard(
                    title: 'Gaji Bersih yang Didapat',
                    rows: [
                      // NOTE: di mockup nilai 2 baris ini beda dari rincian
                      // penerimaan di atas (dummy asli dari desain kamu) —
                      // saya ikutin persis apa adanya, bukan salah ketik saya.
                      ('Gaji Pokok', _formatRupiah(1000000), false),
                      ('Tunjangan', _formatRupiah(1000000), false),
                      ('Total Gaji Bersih', _formatRupiah(_gajiBersih), true),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<(String, String, bool)> rows; // label, value, isBold

  const _SectionCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: kFontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: kAccentBlue,
          ),
        ),
        const SizedBox(height: 4),
        Container(height: 1.5, width: 100, color: kAccentBlue),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: kBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: rows.map((r) {
              final isLast = r == rows.last;
              return Padding(
                padding: EdgeInsets.only(top: 10, bottom: isLast ? 10 : 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      r.$1,
                      style: TextStyle(
                        fontFamily: kFontFamily,
                        fontSize: 13,
                        fontWeight: r.$3 ? FontWeight.w700 : FontWeight.w400,
                        color: r.$3 ? kTextPrimary : kTextSecondary,
                      ),
                    ),
                    Text(
                      ': ${r.$2}',
                      style: TextStyle(
                        fontFamily: kFontFamily,
                        fontSize: 13,
                        fontWeight: r.$3 ? FontWeight.w700 : FontWeight.w600,
                        color: r.$3 ? kAccentBlue : kTextPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}