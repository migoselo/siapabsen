import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../widgets/greeting_header.dart';
import '../widgets/attendance_status_card.dart';
import '../widgets/gps_status_chip.dart';
import '../../attendance/pages/checkin_location_page.dart';
import '../../../core/widgets/custom_bottom_navbar.dart';
import '../../auth/bloc/auth_bloc.dart';

// TODO: ganti ke widget asli halaman check-in punya temen kamu
// import 'package:nama_project_kamu/features/attendance/ui/check_in_flow_page.dart';

const Color kPrimary = Color(0xFF006948);
const Color kBackground = Color(0xFFFFFFFF);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _activeNavIndex = 0; // 0 = Beranda

  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(const HomeStarted());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      // Bottom nav ditaruh di Scaffold.bottomNavigationBar (pola standar
      // Flutter), bukan di dalam body Column, biar nempel di bawah layar
      // konsisten walau konten di atasnya pendek.
      bottomNavigationBar: BottomNav(
        items: const [
          BottomNavItem(icon: Icons.home_filled, label: 'Beranda'),
          BottomNavItem(icon: Icons.person, label: 'Profil'),
          // TODO: tambah item lain di sini kalau memang ada lebih dari 2
          // (misal "Riwayat" seperti desain awal kamu).
        ],
        activeIndex: _activeNavIndex,
        onTap: (index) {
          setState(() => _activeNavIndex = index);
          // TODO: tambahkan navigasi ke halaman terkait di sini,
          // misal Navigator.pushReplacement(...) sesuai routing project kamu.
        },
      ),
      body: SafeArea(
        child: BlocConsumer<HomeBloc, HomeState>(
          listener: (context, state) {
            if (state.status == HomeStatus.failure &&
                state.errorMessage != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
            }
          },
          builder: (context, state) {
            if (state.status == HomeStatus.initial ||
                state.status == HomeStatus.loading) {
              return const Center(
                child: CircularProgressIndicator(color: kPrimary),
              );
            }

            return SizedBox(
              width: 412,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(
                    builder: (context) {
                      // Ambil nama dari AuthBloc — context.watch biar rebuild otomatis
                      // kalau AuthState berubah (misal abis login).
                      final authState = context.watch<AuthBloc>().state;
                      final userName = authState.user?.name ?? '-';

                      return GreetingHeader(
                        userName: userName,
                        avatarUrl: null, // backend belum ada field foto
                      );
                    },
                  ),
                  // GpsStatusCard posisinya independen dari greeting,
                  // ditaruh di sini sementara — sesuaikan Positioned-nya
                  // ke tempat yang benar sesuai desain kamu.
                  const SizedBox(
                    height: 44,
                  ), // <- placeholder, GreetingHeader & GpsStatusCard dimatiin dulu
                  //const Positioned(top: 29, right: 30, child: GpsStatusCard()),
                  const SizedBox(height: 24),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: AttendanceStatusCard(
                      isCheckedIn: state.isCheckedIn,
                      locationName: state.locationName,
                      checkInTime: state.checkInTime,
                    ),
                  ),

                  const SizedBox(height: 36),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 33),
                    child: _ActionButton(state: state),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final HomeState state;
  const _ActionButton({required this.state});

  @override
  Widget build(BuildContext context) {
    final isSubmitting = state.status == HomeStatus.submitting;

    return SizedBox(
      width: 346,
      height: 60,
      child: ElevatedButton(
        onPressed: isSubmitting ? null : () => _handlePress(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          disabledBackgroundColor: kPrimary.withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.isCheckedIn ? 'Check Out' : 'Check In',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    state.isCheckedIn ? Icons.logout : Icons.login,
                    size: 22,
                    color: Colors.white,
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _handlePress(BuildContext context) async {
    if (state.isCheckedIn) {
      context.read<HomeBloc>().add(const HomeCheckOutRequested());
    } else {
      // TODO: aktifkan setelah ganti import ke widget asli temen kamu
      // await Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckInFlowPage()));
      if (context.mounted) context.read<HomeBloc>().add(const HomeStarted());
    }
  }
}
