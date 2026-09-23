import 'package:flutter/material.dart';

const Color kTextPrimary = Color(0xFF0F172A);
const Color kTextSecondary = Color(0xFF6B7280);
const Color kSuccessGreen = Color(0xFF4CAF50);
const String kFontFamily = 'PlusJakartaSans';

/// Panggil: await showFaceRegistrationSuccessDialog(context);
/// Return otomatis setelah dialog tertutup sendiri (tidak ada tombol lagi).
Future<void> showFaceRegistrationSuccessDialog(
  BuildContext context, {
  Duration displayDuration = const Duration(seconds: 3),
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => _SuccessDialog(displayDuration: displayDuration),
  );
}

class _SuccessDialog extends StatefulWidget {
  final Duration displayDuration;

  const _SuccessDialog({required this.displayDuration});

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog> {
  @override
  void initState() {
    super.initState();
    // Tutup dialog otomatis setelah displayDuration, tanpa perlu tombol.
    Future.delayed(widget.displayDuration, () {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
      }
    });
  }

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
          ],
        ),
      ),
    );
  }
}