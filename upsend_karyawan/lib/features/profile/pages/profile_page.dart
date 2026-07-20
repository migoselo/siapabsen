import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
// Sesuaikan dengan path core API milikmu
import 'package:upsend_karyawan/core/api/api.dart';
import '../widgets/profile_header.dart';
import '../../../core/widgets/custom_bottom_navbar.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  // FUNGSI UNTUK CHECK DATA LANGSUNG KE BACKEND LARAVEL
  Future<String> _fetchUserProfile(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      // Jika token lokal kosong, langsung lempar ke login
      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      // Kirim request ke endpoint check user (sesuaikan route backend-mu, misal '/me' atau '/user')
      final response = await Api.dio.get(
        '/me',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        // Ambil nama dari object user yang dikirim backend
        final String nameFromBackend =
            data['name'] ?? data['data']?['name'] ?? 'User Karyawan';

        // Update data lokal biar sinkron
        await prefs.setString('user_name', nameFromBackend);

        return nameFromBackend;
      } else {
        throw Exception('Gagal memverifikasi user');
      }
    } on DioException catch (e) {
      // Jika token unauthorized (401), hapus session lokal dan balik ke login
      if (e.response?.statusCode == 401) {
        _forceLogout(context);
      }

      // Menggunakan fallback data lokal jika server/koneksi bermasalah sementara
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_name') ?? 'User Karyawan';
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_name') ?? 'User Karyawan';
    }
  }

  // Fungsi logout paksa jika token di backend sudah expired
  Future<void> _forceLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_name');
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  // Fungsi untuk handle logout manual dari tombol
  Future<void> _handleLogout(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      // Hit endpoint logout backend jika ada (opsional)
      if (token != null) {
        await Api.dio.post(
          '/logout',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      }
    } catch (_) {
      // Abaikan error logout api agar proses hapus local storage tetap jalan
    } finally {
      _forceLogout(context);
    }
  }

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
      // FutureBuilder sekarang menunggu respons pengecekan dari API Backend
      bottomNavigationBar: BottomNav(
        items: const [
          BottomNavItem(icon: Icons.home_filled, label: 'Beranda'),
          BottomNavItem(icon: Icons.person, label: 'Profil'),
        ],
        activeIndex: 1, // selalu 1, karena ini halaman Profil
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/home');
          }
          // index == 1 (Profil) gak perlu ngapa-ngapain, udah di halaman ini
        },
      ),
      body: FutureBuilder<String>(
        future: _fetchUserProfile(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF006948)),
            );
          }

          final currentUsername = snapshot.data ?? 'User Karyawan';

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const Spacer(),

                  // --- Bagian Tampilan Identicon Avatar & Nama Otomatis ---
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFD1E7DD),
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: IdenticonAvatar(
                              username:
                                  currentUsername, // Avatar dinamis mengikuti nama asli backend
                              size: 120.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          currentUsername, // Nama real-time dari database backend
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // --- Tombol Keluar Akun ---
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _handleLogout(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE11D48),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Keluar Akun',
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.logout, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
