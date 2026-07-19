import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../widgets/greeting_header.dart';
import '../widgets/attendance_status_card.dart';
import '../widgets/gps_status_chip.dart';

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
  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(const HomeStarted());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: BlocConsumer<HomeBloc, HomeState>(
          listener: (context, state) {
            if (state.status == HomeStatus.failure && state.errorMessage != null) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.errorMessage!)));
            }
          },
          builder: (context, state) {
            if (state.status == HomeStatus.initial || state.status == HomeStatus.loading) {
              return const Center(child: CircularProgressIndicator(color: kPrimary));
            }

            return SizedBox(
              width: 412,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      const GreetingHeader(
                        userName: '-', // TODO: sambungkan ke Auth/User state kamu
                        avatarUrl: null,
                      ),
                      // GpsStatusCard posisinya independen dari greeting,
                      // ditaruh di sini sementara — sesuaikan Positioned-nya
                      // ke tempat yang benar sesuai desain kamu.
                      const Positioned(top: 29, right: 30, child: GpsStatusCard()),
                    ],
                  ),

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    state.isCheckedIn ? 'Check Out' : 'Check In',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Icon(state.isCheckedIn ? Icons.logout : Icons.login, size: 22, color: Colors.white),
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
