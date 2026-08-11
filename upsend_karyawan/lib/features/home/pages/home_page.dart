import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../widgets/greeting_header.dart';
import '../widgets/realtime_clock.dart';
import '../widgets/attendance_info_boxes.dart';
import '../widgets/recent_attendances_list.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../../core/widgets/custom_bottom_navbar.dart';
import '../../attendance/pages/checkin_location_page.dart';
// TODO: import BottomNav punya kamu yang udah jadi, saya gak nyentuh itu.

const Color kDanger = Color(0xFFE11D48);
const Color kBackground = Color(0xFFFFFFFF);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _activeNavIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(const HomeStarted());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _activeNavIndex,
        onTap: (index) async {
          if (index == 2) {
            // Presensi -> buka CheckinLocationPage
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CheckinLocationPage()),
            );
            if (context.mounted) {
              setState(() => _activeNavIndex = 0);
              context.read<HomeBloc>().add(const HomeStarted());
            }
          } else if (index == 1) {
            // Izin
            await Navigator.pushNamed(context, '/izin');
            if (context.mounted) {
              setState(() => _activeNavIndex = 0);
            }
          } else if (index == 3) {
            // Riwayat
            await Navigator.pushNamed(context, '/riwayat');
            if (context.mounted) {
              setState(() => _activeNavIndex = 0);
            }
          } else if (index == 4) {
            // Profil
            await Navigator.pushNamed(context, '/profile');
            if (context.mounted) {
              setState(() => _activeNavIndex = 0);
              context.read<AuthBloc>().add(const AuthCheckRequested());
            }
          } else {
            // Beranda (0)
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
                child: CircularProgressIndicator(color: kDanger),
              );
            }

            final authState = context.watch<AuthBloc>().state;
            final userName = authState.user?.name ?? '-';

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GreetingHeader(userName: userName),
                  const SizedBox(height: 20),

                  const RealtimeClockCard(),
                  const SizedBox(height: 16),

                  AttendanceInfoBoxes(
                    checkInTime: state.checkInTime,
                    locationName: state.locationName,
                    checkOutTime: null,
                  ),
                  const SizedBox(height: 16),

                  if (state.isCheckedIn) ...[
                    _CheckOutButton(
                      isSubmitting: state.status == HomeStatus.submitting,
                      onPressed: () => context.read<HomeBloc>().add(
                        const HomeCheckOutRequested(),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  RecentAttendanceList(
                    history: state.history,
                    onLihatSemua: () async {
                      await Navigator.pushNamed(context, '/riwayat');
                      if (context.mounted) {
                        setState(() => _activeNavIndex = 0);
                      }
                    },
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

class _CheckOutButton extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback onPressed;

  const _CheckOutButton({required this.isSubmitting, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isSubmitting ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2B3A8F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, size: 18, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Check Out sekarang',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
