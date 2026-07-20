import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart'; // Ditambahkan untuk menghandle DioException
// Sesuaikan dengan path core API milikmu
import 'package:upsend_karyawan/core/api/api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:upsend_karyawan/features/auth/bloc/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // FUNGSI LOGIC LOGIN KE SERVER LARAVEL
  Future<void> _login() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (phone.isEmpty || password.isEmpty) {
      _showSnackBar('Nomor HP dan Password wajib diisi!');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Menggunakan Api.dio.post langsung karena propertinya berupa static final
      final response = await Api.dio.post(
        '/login',
        data: {
          'no_hp':
              phone, // Disesuaikan dengan penamaan field request backend kamu
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        // Ambil token dari response data backend
        final token = response.data['token'] ?? response.data['access_token'];
        final userData = response.data['user'];

        if (token != null) {
          // Simpan token ke SharedPreferences agar terbaca oleh Interceptor di api.dart
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);

          // --- SIMPAN NAMA USER KE LOCAL STORAGE ---
          if (userData != null && userData['name'] != null) {
            await prefs.setString('user_name', userData['name'].toString());
          } else {
            // Fallback jika backend mengembalikan nama di tingkat utama root response
            final fallbackName = response.data['name'];
            if (fallbackName != null) {
              await prefs.setString('user_name', fallbackName.toString());
            }
          }

          _showSnackBar('Login Berhasil!');

          if (mounted) {
            context.read<AuthBloc>().add(const AuthCheckRequested()); 
            // Pindah ke halaman Dashboard / Main App dan hapus tumpukan stack navigasi
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          _showSnackBar('Token tidak ditemukan dari respon server.');
        }
      }
    } on DioException catch (e) {
      // Menangkap error dari Laravel (422, 401, 403, dll) secara terstruktur
      if (e.response != null) {
        final data = e.response?.data;
        if (data != null && data['errors'] != null) {
          // Jika ada error validasi spesifik (misal: 'no_hp' harus diisi), ambil pesan pertama
          final firstError = (data['errors'] as Map).values.first[0];
          _showSnackBar(firstError.toString());
        } else {
          // Menampilkan message custom dari backend seperti 'Nomor HP atau password salah.'
          _showSnackBar(data?['message'] ?? 'Gagal masuk, silakan coba lagi.');
        }
      } else {
        _showSnackBar(
          'Gagal terhubung ke server. Periksa koneksi internet Anda.',
        );
      }
    } catch (e) {
      _showSnackBar('Terjadi kesalahan sistem.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF006948);
    const Color grayText = Color(0xFF9A9A9A);
    const Color grayBorder = Color(0xFFD9D9D9);

    final inputBorderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: grayBorder, width: 1.0),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 33.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(flex: 2),

                      // --- HEADER SECTIONS ---
                      Text(
                        'Masuk ke Akun',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Masukkan detail Anda untuk melanjutkan',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: grayText,
                        ),
                      ),
                      const Spacer(flex: 1),

                      // --- FORM INPUT: NOMOR HP ---
                      Text(
                        'Nomor HP',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Masukkan nomor HP',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            color: grayText,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.phone_outlined,
                            color: grayText,
                            size: 22,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 18.0,
                            horizontal: 16.0,
                          ),
                          border: inputBorderStyle,
                          enabledBorder: inputBorderStyle,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // --- FORM INPUT: PASSWORD ---
                      Text(
                        'Password',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Masukkan password',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            color: grayText,
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: grayText,
                            size: 22,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 18.0,
                            horizontal: 16.0,
                          ),
                          border: inputBorderStyle,
                          enabledBorder: inputBorderStyle,
                        ),
                      ),

                      const Spacer(flex: 3),

                      // --- BOTTOM ACTIONS (Button & Register Link) ---
                      ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Masuk',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Belum punya akun? ',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: grayText,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/register_page');
                            },
                            child: Text(
                              'Daftar di sini',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40.0),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
