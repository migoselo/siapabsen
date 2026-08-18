import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/history_bloc.dart';
import '../bloc/history_event.dart';
import '../bloc/history_state.dart';
import '../widgets/riwayat_card.dart';
import '../widgets/riwayat_periode_toggle.dart';
import '../widgets/riwayat_periode_strip.dart';
import '../widgets/riwayat_category_chart.dart';
import '../../attendance/models/attendance_model.dart';
import 'riwayat_detail_page.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/widgets/custom_bottom_navbar.dart';
import '../../attendance/pages/checkin_location_page.dart';

class RiwayatPage extends StatefulWidget {
  final bool showBottomNav;
  final bool showBackButton;

  const RiwayatPage({
    super.key,
    this.showBottomNav = true,
    this.showBackButton = true,
  });

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  final DateTime _today = DateTime.now();
  PeriodeRiwayat _periode = PeriodeRiwayat.mingguan;
  late DateTime _anchorDate = _today;
  String? _selectedKategori;
  DateTimeRange?
  _customRange; // aktif kalau user pilih rentang manual lewat kalender

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchForPeriode());
  }

  // Hitung rentang tanggal (dari custom range, atau dari periode aktif), lalu fetch ke bloc
  void _fetchForPeriode() {
    late DateTime start;
    late DateTime end;

    if (_customRange != null) {
      start = _customRange!.start;
      end = _customRange!.end;
    } else {
      switch (_periode) {
        case PeriodeRiwayat.mingguan:
          start = _anchorDate.subtract(Duration(days: _anchorDate.weekday - 1));
          end = start.add(const Duration(days: 6));
          break;
        case PeriodeRiwayat.bulanan:
          start = DateTime(_anchorDate.year, _anchorDate.month, 1);
          end = DateTime(_anchorDate.year, _anchorDate.month + 1, 0);
          break;
        case PeriodeRiwayat.tahunan:
          start = DateTime(_anchorDate.year, 1, 1);
          end = DateTime(_anchorDate.year, 12, 31);
          break;
      }
    }

    context.read<HistoryBloc>().add(
      HistoryFetchRequested(startDate: start, endDate: end),
    );
  }

  void _onPeriodeChanged(PeriodeRiwayat p) {
    setState(() {
      _periode = p;
      _selectedKategori = null;
      _customRange = null;
    });
    _fetchForPeriode();
  }

  void _onStripSelected(DateTime date) {
    setState(() {
      _anchorDate = date;
      _customRange = null;
    });
    _fetchForPeriode();
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      locale: const Locale('id', 'ID'),
      firstDate: DateTime(2020),
      lastDate: _today,
      initialDateRange:
          _customRange ??
          DateTimeRange(
            start: _anchorDate.subtract(const Duration(days: 6)),
            end: _anchorDate,
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1B2559),
              primaryContainer: Color(0xFFB7C0DF),
              onPrimaryContainer: Colors.white,
            ),
            datePickerTheme: const DatePickerThemeData(
              rangeSelectionBackgroundColor: Color(0xFFB7C0DF),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _customRange = picked;
        _selectedKategori = null;
      });
      _fetchForPeriode();
    }
  }

  String get _currentHeader {
    if (_customRange != null) {
      final start = _customRange!.start;
      final end = _customRange!.end;
      final sameMonth = start.month == end.month && start.year == end.year;
      if (sameMonth) {
        return '${DateFormat('d', 'id_ID').format(start)} - '
            '${DateFormat('d MMMM yyyy', 'id_ID').format(end)}';
      }
      return '${DateFormat('d MMM', 'id_ID').format(start)} - '
          '${DateFormat('d MMM yyyy', 'id_ID').format(end)}';
    }
    final headerFormat = _periode == PeriodeRiwayat.tahunan
        ? DateFormat('yyyy', 'id_ID')
        : DateFormat('MMMM yyyy', 'id_ID');
    return headerFormat.format(_anchorDate);
  }

  Map<String, List<AttendanceModel>> _groupByDate(
    List<AttendanceModel> records,
  ) {
    final Map<String, List<AttendanceModel>> grouped = {};
    for (final r in records) {
      final key = DateFormat(
        'EEEE, d MMMM yyyy',
        'id_ID',
      ).format(r.checkInTime.toLocal());
      grouped.putIfAbsent(key, () => []).add(r);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
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
        title: const Text(
          'Riwayat',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? CustomBottomNavBar(
              currentIndex: 3,
              onTap: (index) async {
                if (index == 3) return;
                if (index == 2) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CheckinLocationPage(),
                    ),
                  );
                  if (context.mounted) Navigator.pop(context);
                } else if (index == 1) {
                  Navigator.pushReplacementNamed(context, '/izin');
                } else if (index == 4) {
                  Navigator.pushReplacementNamed(context, '/profile');
                } else {
                  if (Navigator.of(context).canPop()) {
                    Navigator.popUntil(context, ModalRoute.withName('/home'));
                  } else {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (route) => false,
                    );
                  }
                }
              },
            )
          : null,
      body: BlocBuilder<HistoryBloc, HistoryState>(
        builder: (context, state) {
          if (state.status == HistoryStatus.loading && state.records.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B2559)),
            );
          }

          if (state.status == HistoryStatus.failure) {
            return Center(
              child: Text(state.errorMessage ?? 'Gagal memuat riwayat'),
            );
          }

          final filteredRecords = _selectedKategori == null
              ? state.records
              : state.records
                    .where(
                      (r) =>
                          r.status.toLowerCase() ==
                          _selectedKategori!.toLowerCase(),
                    )
                    .toList();
          final grouped = _groupByDate(filteredRecords);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _currentHeader,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _pickDateRange(context),
                      child: SvgPicture.asset(
                        'assets/images/Calendar.svg',
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF2F3B69),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_customRange == null) ...[
                  RiwayatPeriodeToggle(
                    selected: _periode,
                    onChanged: _onPeriodeChanged,
                  ),
                  const SizedBox(height: 16),
                  RiwayatPeriodeStrip(
                    periode: _periode,
                    anchorDate: _anchorDate,
                    today: _today,
                    onSelected: _onStripSelected,
                  ),
                  const SizedBox(height: 16),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _customRange = null);
                        _fetchForPeriode();
                      },
                      child: Row(
                        children: const [
                          Icon(Icons.close, size: 16, color: Color(0xFF9A9A9A)),
                          SizedBox(width: 4),
                          Text(
                            'Hapus filter rentang tanggal',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9A9A9A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                RiwayatCategoryChart(
                  records: state.records,
                  selectedKategori: _selectedKategori,
                  onKategoriTap: (key) {
                    setState(() => _selectedKategori = key);
                  },
                ),
                const SizedBox(height: 20),

                const Text(
                  'Data Presensi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),

                if (filteredRecords.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Belum ada riwayat presensi.',
                      style: TextStyle(color: Color(0xFF9A9A9A)),
                    ),
                  )
                else
                  ...grouped.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...entry.value.map(
                          (record) => RiwayatCard(
                            record: record,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      RiwayatDetailPage(record: record),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}
