import 'package:flutter/material.dart';

const Color kTextPrimary = Color(0xFF0F172A);
const Color kTextSecondary = Color(0xFF6B7280);
const Color kSuccessGreen = Color(0xFF4CAF50);
const String kFontFamily = 'PlusJakartaSans';

/// Panggil: await showFaceRegistrationSuccessDialog(context);
/// Return setelah user tap "Selesai" (dialog ke-dismiss).
Future<void> showFaceRegistrationSuccessDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const _SuccessDialog(),
  );
}

class _SuccessDialog extends StatelessWidget {
  const _SuccessDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: kSuccessGreen, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pendaftaran Berhasil!',
              style: TextStyle(
                fontFamily: kFontFamily,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Wajah Anda berhasil tersimpan',
              style: TextStyle(fontFamily: kFontFamily, fontSize: 13, color: kTextSecondary),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kSuccessGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text(
                  'Selesai',
                  style: TextStyle(fontFamily: kFontFamily, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}