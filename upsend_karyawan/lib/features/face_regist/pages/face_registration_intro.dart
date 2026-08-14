import 'package:flutter/material.dart';
import 'face_registration_camera_page.dart';

const Color kNavy = Color(0xFF2E3A6E);
const Color kTextPrimary = Color(0xFF0F172A);
const Color kTextSecondary = Color(0xFF6B7280);
const Color kBorder = Color(0xFFE5E7EB);
const Color kIconBg = Color(0xFFE8EEFF);
const String kFontFamily = 'PlusJakartaSans';

class FaceRegistrationIntroPage extends StatelessWidget {
  const FaceRegistrationIntroPage({super.key});

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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 8),
            // NOTE: icon face-scan ini APPROKSIMASI (Icons.face_retouching_natural),
            // bukan asset SVG asli — ganti kalau kamu punya asset khusus.
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(color: kIconBg, shape: BoxShape.circle),
              child: const Icon(Icons.face_retouching_natural, color: kNavy, size: 44),
            ),
            const SizedBox(height: 20),
            const Text(
              'Daftarkan Wajah Anda',
              style: TextStyle(
                fontFamily: kFontFamily,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pastikan pencahayaan cukup dan wajah terlihat jelas untuk presensi yang akurat.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: kFontFamily, fontSize: 13, color: kTextSecondary),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: kBorder),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _TipRow(
                    icon: Icons.face_outlined,
                    title: 'Lepas aksesoris wajah',
                    description: 'Lepas masker atau kacamata hitam yang menutupi bagian wajah.',
                  ),
                  const Divider(height: 1, color: kBorder),
                  _TipRow(
                    icon: Icons.center_focus_strong_outlined,
                    title: 'Posisikan wajah di tengah',
                    description: 'Pastikan seluruh wajah Anda berada di dalam area bingkai yang disediakan.',
                  ),
                  const Divider(height: 1, color: kBorder),
                  _TipRow(
                    icon: Icons.wb_sunny_outlined,
                    title: 'Cari tempat terang',
                    description: 'Gunakan pencahayaan yang terang namun tidak membuat silau atau bayangan gelap.',
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FaceRegistrationCameraPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kNavy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text(
                  'Mulai Daftarkan Wajah',
                  style: TextStyle(
                    fontFamily: kFontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isLast;

  const _TipRow({
    required this.icon,
    required this.title,
    required this.description,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(color: kIconBg, shape: BoxShape.circle),
            child: Icon(icon, color: kNavy, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: kFontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(fontFamily: kFontFamily, fontSize: 12, color: kTextSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}