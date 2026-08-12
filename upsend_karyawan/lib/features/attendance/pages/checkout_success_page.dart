import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../home/bloc/home_bloc.dart';
import '../../home/bloc/home_event.dart';
import '../widgets/attendance_stepper.dart';

class CheckoutSuccessPage extends StatelessWidget {
  final DateTime checkOutTime;

  const CheckoutSuccessPage({super.key, required this.checkOutTime});

  @override
  Widget build(BuildContext context) {
    final timeText = DateFormat('HH:mm').format(checkOutTime.toLocal());
    final dateText = DateFormat(
      'd MMMM yyyy',
      'id_ID',
    ).format(checkOutTime.toLocal());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Check Out',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: AttendanceStepper(
        currentStep: 3,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 160,
                    width: 90,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.blueGrey.shade800,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2B3A8F),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Icon(
                    Icons.exit_to_app,
                    size: 140,
                    color: Colors.blueGrey.shade800,
                  ),
                ],
              ),
              const SizedBox(height: 36),
              const Text(
                'Check Out Sukses',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Anda pulang pukul',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                timeText,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 62,
                  color: Color(0xFF2B3A8F),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Berhasil checkout pada tanggal $dateText',
                style: const TextStyle(
                  color: Color(0xFF2B3A8F),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2B3A8F),
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  context.read<HomeBloc>().add(const HomeStarted());
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text(
                  'Kembali ke beranda',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
