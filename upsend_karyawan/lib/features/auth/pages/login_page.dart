import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:upsend_karyawan/features/auth/bloc/auth_bloc.dart';

enum LoginType { email, employeeId, phone }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  LoginType _currentLoginType = LoginType.email;
  bool _obscurePassword = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  static const Color primaryColor = Color(0xFF2D365C);
  static const Color textColor = Color(0xFF0F172A);
  static const Color subtitleColor = Color(0xFF8A94A6);
  static const Color borderColor = Color(0xFFCBD5E1);

  TextStyle _jakartaStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color color = textColor,
    double? height,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _companyController.dispose();
    _employeeIdController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _getLoginIdentifier() {
    switch (_currentLoginType) {
      case LoginType.email:
        return _emailController.text.trim();
      case LoginType.employeeId:
        final company = _companyController.text.trim();
        if (company.isNotEmpty) return company;
        return _employeeIdController.text.trim();
      case LoginType.phone:
        return _phoneController.text.trim();
    }
  }

  void _login() {
    final identifier = _getLoginIdentifier();
    final password = _passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      _showSnackBar('Email/ID/nomor HP dan password wajib diisi!');
      return;
    }

    context.read<AuthBloc>().add(
      AuthLoginRequested(noHp: identifier, password: password),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          _showSnackBar('Login Berhasil!');
          Navigator.pushReplacementNamed(context, '/home');
        } else if (state.status == AuthStatus.failure) {
          _showSnackBar(
            state.errorMessage ?? 'Gagal masuk, silakan coba lagi.',
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 24.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: SvgPicture.asset(
                      'assets/images/Logo.svg',
                      height: 72,
                      width: 72,
                      placeholderBuilder: (context) => const Icon(
                        Icons.navigation_rounded,
                        size: 72,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Masuk ke Akun',
                    textAlign: TextAlign.center,
                    style: _jakartaStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Masukkan detail Anda untuk melanjutkan',
                    textAlign: TextAlign.center,
                    style: _jakartaStyle(
                      fontSize: 14,
                      color: subtitleColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildFormByLoginType(),
                  const SizedBox(height: 32),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormByLoginType() {
    switch (_currentLoginType) {
      case LoginType.email:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Email'),
            _buildInputField(
              controller: _emailController,
              hintText: 'Masukkan Email',
              prefixIcon: Icons.mail_outline_rounded,
            ),
            const SizedBox(height: 18),
            _buildLabel('Password'),
            _buildPasswordField(),
            _buildForgotPasswordButton(),
          ],
        );

      case LoginType.employeeId:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Nama pengguna perusahaan'),
            _buildInputField(
              controller: _companyController,
              hintText: 'Masukkan Email',
              prefixIcon: Icons.mail_outline_rounded,
            ),
            const SizedBox(height: 18),
            _buildLabel('ID karyawan'),
            _buildInputField(
              controller: _employeeIdController,
              hintText: 'Masukkan ID karyawan',
            ),
            const SizedBox(height: 18),
            _buildLabel('Password'),
            _buildPasswordField(),
            _buildForgotPasswordButton(),
          ],
        );

      case LoginType.phone:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Nomor Telepon'),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: borderColor),
                      left: BorderSide(color: borderColor),
                      bottom: BorderSide(color: borderColor),
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: Text(
                    '+62',
                    style: _jakartaStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildInputField(
                    controller: _phoneController,
                    hintText: 'Masukkan nomor telepon',
                    keyboardType: TextInputType.phone,
                    isPhonePrefix: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _buildLabel('Password'),
            _buildPasswordField(),
            _buildForgotPasswordButton(),
          ],
        );
    }
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: _jakartaStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool isPhonePrefix = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: _jakartaStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: _jakartaStyle(color: subtitleColor, fontSize: 14),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: subtitleColor, size: 20)
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: isPhonePrefix
              ? const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                )
              : BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: isPhonePrefix
              ? const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                )
              : BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: _jakartaStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Masukkan Kata Sandi',
        hintStyle: _jakartaStyle(color: subtitleColor, fontSize: 14),
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          color: subtitleColor,
          size: 20,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: primaryColor,
            size: 20,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {},
        child: Text(
          'Lupa password',
          style: _jakartaStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final isLoading = state.status == AuthStatus.authenticating;
              return ElevatedButton(
                onPressed: isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
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
                        style: _jakartaStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        if (_currentLoginType != LoginType.employeeId)
          _buildSecondaryButton(
            text: 'Masuk dengan ID Karyawan',
            onPressed: () {
              setState(() {
                _currentLoginType = LoginType.employeeId;
              });
            },
          ),
        if (_currentLoginType == LoginType.employeeId)
          _buildSecondaryButton(
            text: 'Masuk dengan email',
            onPressed: () {
              setState(() {
                _currentLoginType = LoginType.email;
              });
            },
          ),
        if (_currentLoginType != LoginType.phone)
          _buildSecondaryButton(
            text: 'Masuk dengan nomor telepon',
            onPressed: () {
              setState(() {
                _currentLoginType = LoginType.phone;
              });
            },
          ),
        if (_currentLoginType == LoginType.phone)
          _buildSecondaryButton(
            text: 'Masuk dengan email',
            onPressed: () {
              setState(() {
                _currentLoginType = LoginType.email;
              });
            },
          ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSecondaryButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: borderColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            text,
            style: _jakartaStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}
