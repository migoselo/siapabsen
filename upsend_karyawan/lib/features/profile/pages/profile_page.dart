import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/profile_header.dart';
import '../../../core/widgets/custom_bottom_navbar.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/pages/edit_password_page.dart';

const Color kTextPrimary = Color(0xFF0F172A);
const Color kTextSecondary = Color(0xFF6B7280);
const Color kDanger = Color(0xFFE11D48);
const Color kBorder = Color(0xFFE5E7EB);

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

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
        title: const Text(
          'Profil',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 4, // Profil = index 4
        onTap: (index) {
          if (index == 4) return; // udah di Profil
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/home');
          }
          // TODO: index 1 (Izin), 2 (Presensi), 3 (Riwayat) — arahkan
          // ke halaman masing-masing kalau udah ada, sementara belum
          // saya tau route/widget-nya.
        },
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.unauthenticated) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
          }
        },
        builder: (context, state) {
          if (state.status == AuthStatus.authenticating ||
              state.status == AuthStatus.unknown) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF006948)),
            );
          }

          final user = state.user;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      ClipOval(
                        child: IdenticonAvatar(
                          username: user?.name ?? '-',
                          size: 100.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user?.name ?? '-',
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? '-',
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 13,
                          color: kTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                const Text(
                  'Informasi Akun',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kTextSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: kBorder),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // <- TAMBAHIN INI
                    children: [
                      _InfoRow(
                        label: 'ID Karyawan',
                        value: user?.employeeCode ?? '-',
                      ),
                      const Divider(height: 1, color: kBorder),
                      _InfoRow(label: 'Nomor HP', value: user?.noHp ?? '-'),
                      const Divider(height: 1, color: kBorder),
                      _InfoRow(
                        label: 'Lokasi Kerja',
                        value: user?.homeLocationName ?? '-',
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Pengaturan',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kTextSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: kBorder),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _SettingRow(
                        label: 'Edit Password',
                        showChevron: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditPasswordPage(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1, color: kBorder),
                      _SettingRow(
                        label: 'Logout',
                        textColor: kDanger,
                        onTap: () {
                          context.read<AuthBloc>().add(
                            const AuthLogoutRequested(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 11,
              color: kTextSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: kTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final bool showChevron;
  final Color? textColor;
  final VoidCallback onTap;

  const _SettingRow({
    required this.label,
    this.showChevron = false,
    this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textColor ?? kTextPrimary,
              ),
            ),
            if (showChevron)
              const Icon(Icons.chevron_right, color: kTextSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
