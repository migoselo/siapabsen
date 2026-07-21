import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../widgets/greeting_header.dart';
import '../widgets/attendance_status_card.dart';
// import '../widgets/gps_status_chip.dart';
import '../../attendance/pages/checkin_location_page.dart';
import '../../../core/widgets/custom_bottom_navbar.dart';
import '../../auth/bloc/auth_bloc.dart';

const Color kPrimary = Color(0xFF006948);
const Color kDanger = Color(0xFFE0224E);
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

    // Refresh data user (nama + otomatis identicon ikut) dari backend
    // setiap kali Home dibuka, pakai AuthRepository.getCurrentUser()
    // yang sekarang sudah handle bentuk respons /me dengan benar.
    // Ini SUMBER YANG SAMA dipakai ProfilePage, jadi nama & avatar
    // di Home & Profile dijamin selalu identik.
    context.read<AuthBloc>().add(const AuthCheckRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      bottomNavigationBar: BottomNav(
        items: const [
          BottomNavItem(icon: Icons.home_filled, label: 'Beranda'),
          BottomNavItem(icon: Icons.person, label: 'Profil'),
        ],
        activeIndex: _activeNavIndex,
        onTap: (index) async {
          if (index == 1) {
            await Navigator.pushNamed(context, '/profile');
            if (context.mounted) {
              setState(() => _activeNavIndex = 0);
              // Balik dari Profile → refresh AuthBloc juga, jaga-jaga
              // kalau ada perubahan data user.
              context.read<AuthBloc>().add(const AuthCheckRequested());
            }
          } else {
            setState(() => _activeNavIndex = index);
          }
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
                      // context.watch biar rebuild otomatis kalau
                      // AuthState berubah (misal AuthCheckRequested
                      // barusan selesai fetch dari /me).
                      final authState = context.watch<AuthBloc>().state;
                      final userName = authState.user?.name ?? '-';

                      return GreetingHeader(userName: userName);
                    },
                  ),
                  const SizedBox(height: 44),
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
    final buttonColor = state.isCheckedIn ? kDanger : kPrimary;

    return SizedBox(
      width: 346,
      height: 60,
      child: ElevatedButton(
        onPressed: isSubmitting ? null : () => _handlePress(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          disabledBackgroundColor: buttonColor.withOpacity(0.6),
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
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const CheckinLocationPage(),
        ), // Sesuaikan nama class halamanmu
      );
      // TODO: aktifkan setelah ganti import ke widget asli temen kamu
      // await Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckInFlowPage()));
      if (context.mounted) context.read<HomeBloc>().add(const HomeStarted());
    }
  }
}
