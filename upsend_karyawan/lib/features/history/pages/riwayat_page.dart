import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/history_bloc.dart';
import '../bloc/history_event.dart';
import '../bloc/history_state.dart';
import '../widgets/riwayat_card.dart';
import '../widgets/riwayat_date_strip.dart';
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
  DateTime? _selectedDate;
  bool _isFilterActive = false;
  final DateTime _today = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryBloc>().add(const HistoryFetchRequested());
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final historyBloc = context.read<HistoryBloc>();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? _today,
      firstDate: DateTime(2020),
      lastDate: _today,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF1B2559)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      if (!mounted) return;
      setState(() {
        _selectedDate = picked;
        _isFilterActive = true;
      });
      historyBloc.add(
        HistoryFetchRequested(startDate: picked, endDate: picked),
      );
    }
  }

  void _onDateStripSelected(DateTime date) {
    setState(() => _selectedDate = date);
    context.read<HistoryBloc>().add(
      HistoryFetchRequested(startDate: date, endDate: date),
    );
  }

  /// Kelompokkan record berdasarkan tanggal check-in (buat header "23 Oktober 2026")
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
    final currentMonthYear = DateFormat(
      'MMMM yyyy',
      'id_ID',
    ).format(_selectedDate ?? _today);

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
                        builder: (_) => const CheckinLocationPage()),
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

          final grouped = _groupByDate(state.records);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      currentMonthYear,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
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

                if (_isFilterActive && _selectedDate != null) ...[
                  RiwayatDateStrip(
                    selectedDate: _selectedDate!,
                    today: _today,
                    onDateSelected: _onDateStripSelected,
                  ),
                  const SizedBox(height: 16),
                ],

                if (state.records.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Belum ada riwayat presensi.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                else
                  ...grouped.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
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
