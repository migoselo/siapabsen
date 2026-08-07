// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:dio/dio.dart';
// // Sesuaikan path import core API dengan struktur project kamu
// import 'package:upsend_karyawan/core/api/api.dart';

// class RegisterPage extends StatefulWidget {
//   const RegisterPage({super.key});

//   @override
//   State<RegisterPage> createState() => _RegisterPageState();
// }

// class _RegisterPageState extends State<RegisterPage> {
//   // Deklarasi seluruh controller
//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _passwordController = TextEditingController();

//   bool _isLoading = false;

//   @override
//   void dispose() {
//     // Pastikan semua controller di-dispose untuk mencegah memory leak
//     _nameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   // Fungsi Register Logic ke Backend Laravel via Api.dio.post
//   Future<void> _register() async {
//     final nama = _nameController.text.trim();
//     final email = _emailController.text.trim();
//     final nomorHp = _phoneController.text.trim();
//     final password = _passwordController.text;

//     if (nama.isEmpty || email.isEmpty || nomorHp.isEmpty || password.isEmpty) {
//       _showSnackBar('Semua field wajib diisi!');
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final response = await Api.dio.post(
//         '/register',
//         data: {
//           'name': nama,
//           'email': email,
//           'password': password,
//           'no_hp': nomorHp,
//           'home_location_id': '1',
//         },
//         options: Options(headers: {'Accept': 'application/json'}),
//       );

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         _showSnackBar('Registrasi Berhasil! Silakan masuk.');
//         if (mounted) {
//           Navigator.pop(
//             context,
//           ); // Kembali ke halaman login setelah berhasil mendaftar
//         }
//       } else {
//         final errorMsg =
//             response.data['message'] ?? 'Gagal melakukan registrasi.';
//         _showSnackBar(errorMsg);
//       }
//     } on DioException catch (e) {
//       // Menangkap detail error validasi (422) langsung dari Laravel
//       if (e.response != null && e.response?.statusCode == 422) {
//         final data = e.response?.data;
//         if (data != null && data['errors'] != null) {
//           final Map<String, dynamic> validationErrors = data['errors'];
//           // Mengambil string pesan error pertama yang digagalkan Laravel
//           final firstError = validationErrors.values.first[0];
//           _showSnackBar('Gagal: $firstError');
//         } else {
//           _showSnackBar(data['message'] ?? 'Data tidak valid (422).');
//         }
//       } else {
//         final errorMsg =
//             e.response?.data['message'] ?? 'Gagal melakukan registrasi.';
//         _showSnackBar(errorMsg);
//       }
//     } catch (e) {
//       _showSnackBar(
//         'Gagal terhubung ke server. Periksa koneksi internet Anda.',
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   void _showSnackBar(String message) {
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(SnackBar(content: Text(message)));
//   }

//   @override
//   Widget build(BuildContext context) {
//     const Color primaryGreen = Color(0xFF006948);
//     const Color grayText = Color(0xFF9A9A9A);
//     const Color grayBorder = Color(0xFFD9D9D9);

//     final inputBorderStyle = OutlineInputBorder(
//       borderRadius: BorderRadius.circular(12),
//       borderSide: const BorderSide(color: grayBorder, width: 1.0),
//     );

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: LayoutBuilder(
//           builder: (context, constraints) {
//             return SingleChildScrollView(
//               padding: const EdgeInsets.symmetric(horizontal: 33.0),
//               child: ConstrainedBox(
//                 constraints: BoxConstraints(minHeight: constraints.maxHeight),
//                 child: IntrinsicHeight(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: [
//                       const Spacer(flex: 2),

//                       // --- HEADER SECTIONS ---
//                       Text(
//                         'Daftar Akun Baru',
//                         textAlign: TextAlign.center,
//                         style: GoogleFonts.plusJakartaSans(
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'Lengkapi data Anda untuk mendaftar sebagai karyawan',
//                         textAlign: TextAlign.center,
//                         style: GoogleFonts.plusJakartaSans(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                           color: grayText,
//                         ),
//                       ),
//                       const Spacer(flex: 1),

//                       // --- FORM INPUT: NAMA LENGKAP ---
//                       Text(
//                         'Nama Lengkap',
//                         style: GoogleFonts.plusJakartaSans(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.black,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       TextField(
//                         controller: _nameController,
//                         keyboardType: TextInputType.name,
//                         decoration: InputDecoration(
//                           isDense: true,
//                           hintText: 'Masukkan nama lengkap',
//                           hintStyle: GoogleFonts.plusJakartaSans(
//                             color: grayText,
//                             fontSize: 14,
//                           ),
//                           prefixIcon: const Icon(
//                             Icons.person_outline,
//                             color: grayText,
//                             size: 22,
//                           ),
//                           contentPadding: const EdgeInsets.symmetric(
//                             vertical: 18.0,
//                             horizontal: 16.0,
//                           ),
//                           border: inputBorderStyle,
//                           enabledBorder: inputBorderStyle,
//                         ),
//                       ),
//                       const SizedBox(height: 20),

//                       // --- FORM INPUT: EMAIL ---
//                       Text(
//                         'Email',
//                         style: GoogleFonts.plusJakartaSans(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.black,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       TextField(
//                         controller: _emailController,
//                         keyboardType: TextInputType.emailAddress,
//                         decoration: InputDecoration(
//                           isDense: true,
//                           hintText: 'Masukkan alamat email',
//                           hintStyle: GoogleFonts.plusJakartaSans(
//                             color: grayText,
//                             fontSize: 14,
//                           ),
//                           prefixIcon: const Icon(
//                             Icons.email_outlined,
//                             color: grayText,
//                             size: 22,
//                           ),
//                           contentPadding: const EdgeInsets.symmetric(
//                             vertical: 18.0,
//                             horizontal: 16.0,
//                           ),
//                           border: inputBorderStyle,
//                           enabledBorder: inputBorderStyle,
//                         ),
//                       ),
//                       const SizedBox(height: 20),

//                       // --- FORM INPUT: NOMOR HP ---
//                       Text(
//                         'Nomor HP',
//                         style: GoogleFonts.plusJakartaSans(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.black,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       TextField(
//                         controller: _phoneController,
//                         keyboardType: TextInputType.phone,
//                         decoration: InputDecoration(
//                           isDense: true,
//                           hintText: 'Masukkan nomor HP aktif',
//                           hintStyle: GoogleFonts.plusJakartaSans(
//                             color: grayText,
//                             fontSize: 14,
//                           ),
//                           prefixIcon: const Icon(
//                             Icons.phone_outlined,
//                             color: grayText,
//                             size: 22,
//                           ),
//                           contentPadding: const EdgeInsets.symmetric(
//                             vertical: 18.0,
//                             horizontal: 16.0,
//                           ),
//                           border: inputBorderStyle,
//                           enabledBorder: inputBorderStyle,
//                         ),
//                       ),
//                       const SizedBox(height: 20),

//                       // --- FORM INPUT: PASSWORD ---
//                       Text(
//                         'Password',
//                         style: GoogleFonts.plusJakartaSans(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.black,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       TextField(
//                         controller: _passwordController,
//                         obscureText: true,
//                         decoration: InputDecoration(
//                           isDense: true,
//                           hintText: 'Masukkan password',
//                           hintStyle: GoogleFonts.plusJakartaSans(
//                             color: grayText,
//                             fontSize: 14,
//                           ),
//                           prefixIcon: const Icon(
//                             Icons.lock_outline,
//                             color: grayText,
//                             size: 22,
//                           ),
//                           contentPadding: const EdgeInsets.symmetric(
//                             vertical: 18.0,
//                             horizontal: 16.0,
//                           ),
//                           border: inputBorderStyle,
//                           enabledBorder: inputBorderStyle,
//                         ),
//                       ),

//                       const Spacer(flex: 3),

//                       // --- BOTTOM ACTIONS ---
//                       ElevatedButton(
//                         onPressed: _isLoading ? null : _register,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: primaryGreen,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(vertical: 16),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           elevation: 0,
//                         ),
//                         child: _isLoading
//                             ? const SizedBox(
//                                 height: 20,
//                                 width: 20,
//                                 child: CircularProgressIndicator(
//                                   color: Colors.white,
//                                   strokeWidth: 2,
//                                 ),
//                               )
//                             : Text(
//                                 'Daftar',
//                                 style: GoogleFonts.plusJakartaSans(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                       ),
//                       const SizedBox(height: 16),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             'Sudah punya akun? ',
//                             style: GoogleFonts.plusJakartaSans(
//                               fontSize: 12,
//                               fontWeight: FontWeight.w500,
//                               color: grayText,
//                             ),
//                           ),
//                           GestureDetector(
//                             onTap: () {
//                               Navigator.pop(
//                                 context,
//                               ); // Kembali ke halaman Login
//                             },
//                             child: Text(
//                               'Masuk di sini',
//                               style: GoogleFonts.plusJakartaSans(
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w600,
//                                 color: primaryGreen,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 40.0),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
