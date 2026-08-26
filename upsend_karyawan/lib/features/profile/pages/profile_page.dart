import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/profile_header.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/pages/edit_password_page.dart';
import '../../face_regist/pages/face_registration_intro.dart';
import '../../../core/widgets/custom_bottom_navbar.dart';
import '../../attendance/pages/checkin_location_page.dart';
import 'biodata_page.dart';

const Color kNavy = Color(0xFF2F3B69);
const Color kTextPrimary = Color(0xFF0F172A);
const Color kTextSecondary = Color(0xFF9A9A9A);
const Color kDanger = Color(0xFFE11D48);
const Color kBorder = Color(0xFFE5E7EB);
const String kFontFamily = 'PlusJakartaSans';

class ProfilePage extends StatelessWidget {
  final bool showBottomNav;
  final bool showBackButton;

  const ProfilePage({
    super.key,
    this.showBottomNav = true,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: showBackButton
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
          'Profil',
          style: TextStyle(
            fontFamily: kFontFamily,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: showBottomNav
          ? CustomBottomNavBar(
              currentIndex: 4, // Profil
              onTap: (index) async {
                if (index == 4) return;

                if (index == 2) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CheckinLocationPage(),
                    ),
                  );
                  if (context.mounted) Navigator.pop(context);
                } else if (index == 1) {
                  await Navigator.pushNamed(context, '/riwayat_cuti');
                  if (context.mounted) Navigator.pop(context);
                } else if (index == 3) {
                  await Navigator.pushNamed(context, '/riwayat');
                  if (context.mounted) Navigator.pop(context);
                } else {
                  if (Navigator.canPop(context)) {
                    Navigator.popUntil(context, ModalRoute.withName('/home'));
                  } else {
                    await Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (route) => false,
                    );
                  }
                }
              },
            )
          : null,
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
            return const Center(child: CircularProgressIndicator(color: kNavy));
          }

          final user = state.user;
          final userName = user?.name ?? '-';
          final userEmail = user?.email ?? '-';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      ClipOval(
                        child: IdenticonAvatar(username: userName, size: 100.0),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        userName,
                        style: const TextStyle(
                          fontFamily: kFontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        userEmail,
                        style: const TextStyle(
                          fontFamily: kFontFamily,
                          fontSize: 13,
                          color: kTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Full time developer', // TODO: dummy
                            style: TextStyle(
                              fontFamily: kFontFamily,
                              fontSize: 12,
                              color: kTextSecondary,
                            ),
                          ),
                          SizedBox(width: 12),
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: kTextSecondary,
                          ),
                          SizedBox(width: 2),
                          Text(
                            'Kantor Pusat', // TODO: dummy
                            style: TextStyle(
                              fontFamily: kFontFamily,
                              fontSize: 12,
                              color: kTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BiodataPage(
                            userName: userName,
                            userEmail: userEmail,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kNavy,
                      minimumSize: const Size.fromHeight(54),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                      alignment: Alignment.center,
                    ),
                    child: const Text(
                      'Lihat Biodata Lengkap',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: kFontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Informasi Akun',
                  style: TextStyle(
                    fontFamily: kFontFamily,
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
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(
                        label: 'ID karyawan',
                        value: user?.employeeCode ?? '-',
                      ),
                      const Divider(height: 1, color: kBorder),
                      _InfoRow(label: 'Nomor HP', value: user?.noHp ?? '-'),
                      const Divider(height: 1, color: kBorder),
                      const _InfoRow(
                        label: 'Departemen',
                        value: 'Developer',
                      ), // TODO: dummy
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Pengaturan',
                  style: TextStyle(
                    fontFamily: kFontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kTextSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: kBorder),
                    borderRadius: BorderRadius.circular(15),
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
                        label: 'Daftarkan Wajah',
                        showChevron: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FaceRegistrationIntroPage(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1, color: kBorder),
                      _SettingRow(
                        label: 'Log Out',
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
  const _InfoRow({required this.label, required this.value});

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
              fontFamily: kFontFamily,
              fontSize: 11,
              color: kTextSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontFamily: kFontFamily,
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
                fontFamily: kFontFamily,
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
