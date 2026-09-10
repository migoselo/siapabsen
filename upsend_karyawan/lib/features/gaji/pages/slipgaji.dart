import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api.dart';
import '../../../core/widgets/riwayat_calendar_dialog.dart';

const Color kNavy = Color(0xFF2F3B69);
const Color kNavyLight = Color(0xFF4E62AF);
const Color kTextPrimary = Color(0xFF0F172A);
const Color kTextSecondary = Color(0xFF6B7280);
const Color kBorder = Color(0xFFE5E7EB);
const Color kAccentBlue = Color(0xFF3B5BDB);
const String kFontFamily = 'PlusJakartaSans';

class _Payroll {
  final Map<String, dynamic> data;

  _Payroll(this.data);

  String? text(String key) => data[key] as String?;
  int money(String key) => (data[key] as num?)?.round() ?? 0;
}

class SlipGajiPage extends StatefulWidget {
  const SlipGajiPage({super.key});

  @override
  State<SlipGajiPage> createState() => _SlipGajiPageState();
}

class _SlipGajiPageState extends State<SlipGajiPage> {
  DateTime _selectedMonth = DateTime.now();
  _Payroll? _payroll;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPayroll();
  }

  Future<void> _loadPayroll() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await Api.dio.get(
        '/payrolls/${_selectedMonth.year}/${_selectedMonth.month}',
      );
      final payroll = _Payroll(response.data as Map<String, dynamic>);
      if (!mounted) return;
      setState(() {
        _payroll = payroll;
        _isLoading = false;
      });
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() {
        _payroll = error.response?.statusCode == 404 ? null : _payroll;
        _isLoading = false;
      });
    }
  }

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
        _selectedMonth = result.range != null
            ? result.range!.start
            : result.date;
      });
      _loadPayroll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final payroll = _payroll;

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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: kNavyLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: Colors.white,
                          size: 18,
                        ),
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
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                        ),
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
                            style: TextStyle(
                              fontFamily: kFontFamily,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            payroll == null
                                ? '-'
                                : _formatRupiah(payroll.money('net_salary')),
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
                          onPressed: null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
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

          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (payroll == null)
            const Expanded(child: SizedBox.shrink())
          else
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
                        ('Nama Bank', payroll.text('bank_name') ?? '-', false),
                        (
                          'Akun Penerima',
                          payroll.text('bank_account_name') ?? '-',
                          false,
                        ),
                        (
                          'Nomor Rekening',
                          payroll.text('bank_account_number') ?? '-',
                          false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _SectionCard(
                      title: 'Rincian Penerimaan',
                      rows: [
                        (
                          'Gaji Pokok',
                          _formatRupiah(payroll.money('basic_salary')),
                          false,
                        ),
                        (
                          'Transport',
                          _formatRupiah(payroll.money('transport_allowance')),
                          false,
                        ),
                        (
                          'Makan',
                          _formatRupiah(payroll.money('meal_allowance')),
                          false,
                        ),
                        (
                          'Kehadiran',
                          _formatRupiah(payroll.money('attendance_allowance')),
                          false,
                        ),
                        (
                          'Tunjangan Lainnya',
                          _formatRupiah(payroll.money('other_allowance')),
                          false,
                        ),
                        (
                          'Total Penerimaan',
                          _formatRupiah(payroll.money('total_income')),
                          true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _SectionCard(
                      title: 'Rincian Potongan',
                      rows: [
                        (
                          'Mangkir (${payroll.money('absence_days')}/${payroll.money('effective_work_days')} hari)',
                          _formatRupiah(payroll.money('absence_deduction')),
                          false,
                        ),
                        (
                          'Keterlambatan (${payroll.money('late_minutes')} menit)',
                          _formatRupiah(payroll.money('late_deduction')),
                          false,
                        ),
                        (
                          'Cicilan Bank',
                          _formatRupiah(payroll.money('loan_deduction')),
                          false,
                        ),
                        (
                          'Pajak',
                          _formatRupiah(payroll.money('tax_deduction')),
                          false,
                        ),
                        (
                          'Potongan Lainnya',
                          _formatRupiah(payroll.money('other_deduction')),
                          false,
                        ),
                        (
                          'Total Potongan',
                          _formatRupiah(payroll.money('total_deduction')),
                          true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _SectionCard(
                      title: 'Gaji Bersih yang Didapat',
                      rows: [
                        (
                          'Total Gaji Bersih',
                          _formatRupiah(payroll.money('net_salary')),
                          true,
                        ),
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
