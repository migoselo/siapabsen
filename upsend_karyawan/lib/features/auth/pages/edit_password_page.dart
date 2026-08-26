import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/auth_repository.dart';
import 'reset_password_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

const Color kDarkBlue = Color(0xFF2F3B69);
const Color kTextSecondary = Color(0xFF6B7280);
const Color kBorder = Color(0xFFD9D9D9);
const String kFontFamily = 'PlusJakartaSans';

class EditPasswordPage extends StatefulWidget {
  const EditPasswordPage({super.key});

  @override
  State<EditPasswordPage> createState() => _EditPasswordPageState();
}

class _EditPasswordPageState extends State<EditPasswordPage> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message.replaceFirst('Exception: ', ''))),
    );
  }

  Future<void> _submit() async {
    final oldPassword = _oldPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar('Semua field wajib diisi.');
      return;
    }
    if (newPassword.length < 6) {
      _showSnackBar('Password baru minimal 6 karakter.');
      return;
    }
    if (newPassword != confirmPassword) {
      _showSnackBar('Password baru dan ulangi password tidak sama.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<AuthRepository>().changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
        newPasswordConfirmation: confirmPassword,
      );
      if (!mounted) return;
      _showSnackBar('Password berhasil diubah.');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header biru melengkung
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                bottom: 60,
                left: 16,
                right: 16,
              ),
              decoration: const BoxDecoration(
                color: kDarkBlue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Edit Password',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: kFontFamily,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // seimbangin lebar tombol back
                ],
              ),
            ),

            // Card putih menimpa header (offset negatif)
            Transform.translate(
              offset: const Offset(0, -50),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ubah Password',
                      style: TextStyle(
                        fontFamily: kFontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: kTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _PasswordField(
                      label: 'Password Lama',
                      hint: 'Masukkan password lama',
                      controller: _oldPasswordController,
                      obscure: _obscureOld,
                      onToggle: () =>
                          setState(() => _obscureOld = !_obscureOld),
                    ),
                    const SizedBox(height: 16),

                    _PasswordField(
                      label: 'Password Baru',
                      hint: 'Masukkan password baru',
                      controller: _newPasswordController,
                      obscure: _obscureNew,
                      onToggle: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                    const SizedBox(height: 16),

                    _PasswordField(
                      label: 'Ulangi Password Baru',
                      hint: 'Masukkan ulang password baru',
                      controller: _confirmPasswordController,
                      obscure: _obscureConfirm,
                      onToggle: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kDarkBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Simpan',
                                style: TextStyle(
                                  fontFamily: kFontFamily,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ResetPasswordScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Lupa Password',
                          style: TextStyle(
                            fontFamily: kFontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: kDarkBlue,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: kFontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: kDarkBlue,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(fontFamily: kFontFamily, fontSize: 14),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: const TextStyle(
              fontFamily: kFontFamily,
              fontSize: 13,
              color: kTextSecondary,
            ),
            suffixIcon: GestureDetector(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: SvgPicture.asset(
                  obscure
                      ? 'assets/images/Eye.svg'
                      : 'assets/images/Eye_Closed.svg',
                  colorFilter: const ColorFilter.mode(
                    kDarkBlue,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kBorder),
            ),
          ),
        ),
      ],
    );
  }
}
