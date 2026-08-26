import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:upsend_karyawan/features/auth/bloc/auth_bloc.dart';
import 'package:upsend_karyawan/core/widgets/custom_snackbar.dart';
import 'package:upsend_karyawan/features/auth/pages/reset_password_screen.dart';

enum LoginType { email, employeeId, phone }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with WidgetsBindingObserver {
  LoginType _currentLoginType = LoginType.email;
  bool _obscurePassword = true;

  static const double _keyboardScrollOffset = 140.0;

  final ScrollController _scrollController = ScrollController();
  bool _keyboardWasOpen = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  static const Color primaryColor = Color(0xFF2F3B69);
  static const Color textColor = Color(0xFF0F172A);
  static const Color subtitleColor = Color(0xFF9A9A9A);
  static const Color selectorBackground = Color(0xFFF3F3F3);
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _applyScrollPosition() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      final target = _keyboardWasOpen ? _keyboardScrollOffset : 0.0;
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void didChangeMetrics() {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    if (keyboardOpen && !_keyboardWasOpen) {
      _keyboardWasOpen = true;
      _applyScrollPosition();
    } else if (!keyboardOpen && _keyboardWasOpen) {
      _keyboardWasOpen = false;
      _applyScrollPosition();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
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

    final identifierEmpty = identifier.isEmpty;
    final passwordEmpty = password.isEmpty;

    // 1. Cek kosong dulu (kombinasi & satu-satu)
    if (identifierEmpty && passwordEmpty) {
      AppSnackbar.warning(context, _getBothEmptyMessage());
      return;
    }

    if (identifierEmpty) {
      AppSnackbar.warning(context, _getIdentifierOnlyMessage());
      return;
    }

    if (passwordEmpty) {
      AppSnackbar.warning(context, 'Password wajib diisi!');
      return;
    }

    // 2. Cek format identifier sesuai tab aktif
    final formatError = _validateIdentifierFormat(identifier);
    if (formatError != null) {
      AppSnackbar.warning(context, formatError);
      return;
    }

    // 3. Cek panjang minimum password
    if (password.length < 6) {
      AppSnackbar.warning(context, 'Password minimal 6 karakter!');
      return;
    }

    context.read<AuthBloc>().add(
      AuthLoginRequested(noHp: identifier, password: password),
    );
  }

  /// Balikin pesan error kalau format identifier gak valid, null kalau valid
  String? _validateIdentifierFormat(String identifier) {
    switch (_currentLoginType) {
      case LoginType.email:
        if (!_isValidEmail(identifier)) {
          return 'Format email tidak valid!';
        }
        return null;

      case LoginType.employeeId:
        final company = _companyController.text.trim();
        final employeeId = _employeeIdController.text.trim();
        if (company.isNotEmpty && !_isValidEmail(company)) {
          return 'Format kantor cabang tidak valid!';
        }
        if (employeeId.isEmpty) {
          return 'ID karyawan wajib diisi!';
        }
        return null;

      case LoginType.phone:
        if (!_isValidPhone(identifier)) {
          return 'Format nomor telepon tidak valid! Gunakan angka saja, 9-15 digit.';
        }
        return null;
    }
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    final regex = RegExp(r'^[0-9]{9,15}$');
    return regex.hasMatch(phone);
  }

  String _getFailureMessage(String? backendMessage) {
    final cleaned = (backendMessage ?? '').replaceFirst('Exception: ', '');

    final isInvalidCredential =
        cleaned.toLowerCase().contains('salah') ||
        cleaned.toLowerCase().contains('invalid') ||
        cleaned.toLowerCase().contains('tidak ditemukan') ||
        cleaned.isEmpty;

    if (isInvalidCredential) {
      switch (_currentLoginType) {
        case LoginType.email:
          return 'Email atau Password salah.';
        case LoginType.employeeId:
          return 'Kantor Cabang, ID Karyawan, atau Password salah.';
        case LoginType.phone:
          return 'Nomor Telepon atau Password salah.';
      }
    }

    return cleaned.isEmpty ? 'Gagal masuk, silakan coba lagi.' : cleaned;
  }

  String _getBothEmptyMessage() {
    switch (_currentLoginType) {
      case LoginType.email:
        return 'Email dan Password wajib diisi!';
      case LoginType.employeeId:
        return 'Kantor Cabang, ID Karyawan, dan Password wajib diisi!';
      case LoginType.phone:
        return 'Nomor Telepon dan Password wajib diisi!';
    }
  }

  String _getIdentifierOnlyMessage() {
    switch (_currentLoginType) {
      case LoginType.email:
        return 'Email wajib diisi!';
      case LoginType.employeeId:
        return 'Kantor Cabang dan ID Karyawan wajib diisi!';
      case LoginType.phone:
        return 'Nomor Telepon wajib diisi!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          AppSnackbar.success(context, 'Login Berhasil!');
          Navigator.pushReplacementNamed(context, '/home');
        } else if (state.status == AuthStatus.failure) {
          AppSnackbar.error(context, _getFailureMessage(state.errorMessage));
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    24.0,
                    24.0,
                    24.0,
                    24.0 + keyboardInset,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 5),
                      Center(
                        child: SvgPicture.asset(
                          'assets/images/Logo2.svg',
                          height: 100,
                          width: 100,
                          placeholderBuilder: (context) => const Icon(
                            Icons.navigation_rounded,
                            size: 72,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Masuk ke Akun',
                        textAlign: TextAlign.center,
                        style: _jakartaStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Masukkan detail Anda untuk melanjutkan',
                        textAlign: TextAlign.center,
                        style: _jakartaStyle(
                          fontSize: 16,
                          color: subtitleColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildLoginTypeSelector(),
                      const SizedBox(height: 24),
                      _buildFormByLoginType(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 10),
                child: _buildActionButtons(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginTypeSelector() {
    const options = [
      (LoginType.email, 'Email'),
      (LoginType.employeeId, 'ID Karyawan'),
      (LoginType.phone, 'Telepon'),
    ];

    return Container(
      height: 55,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: selectorBackground,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (_currentLoginType != option.$1) {
                    setState(() => _currentLoginType = option.$1);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _currentLoginType == option.$1
                        ? primaryColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    option.$2,
                    textAlign: TextAlign.center,
                    style: _jakartaStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _currentLoginType == option.$1
                          ? Colors.white
                          : subtitleColor,
                    ),
                  ),
                ),
              ),
            ),
        ],
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
              prefixIconAsset: 'assets/images/Message.svg',
              prefixIconSize: const Size(16, 16),
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
            _buildLabel('Kantor Cabang'),
            _buildInputField(
              controller: _companyController,
              hintText: 'Masukkan nama kantor cabang',
              prefixIconAsset: 'assets/images/Message.svg',
              prefixIconSize: const Size(16, 16),
            ),
            const SizedBox(height: 18),
            _buildLabel('ID Karyawan'),
            _buildInputField(
              controller: _employeeIdController,
              hintText: 'Masukkan ID karyawan',
              prefixIconAsset: 'assets/images/ID.svg',
              prefixIconSize: const Size(22, 22),
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
    String? prefixIconAsset,
    Size? prefixIconSize,
    TextInputType keyboardType = TextInputType.text,
    bool isPhonePrefix = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: _jakartaStyle(fontSize: 14),
      scrollPadding: const EdgeInsets.all(20),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: _jakartaStyle(color: subtitleColor, fontSize: 14),
        prefixIcon: prefixIconAsset != null
            ? Padding(
                padding: const EdgeInsets.all(14),
                child: SvgPicture.asset(
                  prefixIconAsset,
                  width: prefixIconSize?.width,
                  height: prefixIconSize?.height,
                  colorFilter: const ColorFilter.mode(
                    subtitleColor,
                    BlendMode.srcIn,
                  ),
                ),
              )
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
      scrollPadding: const EdgeInsets.all(20),
      decoration: InputDecoration(
        hintText: 'Masukkan Kata Sandi',
        hintStyle: _jakartaStyle(color: subtitleColor, fontSize: 14),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(14),
          child: SvgPicture.asset(
            'assets/images/Lock.svg',
            width: 20,
            height: 20,
            colorFilter: const ColorFilter.mode(subtitleColor, BlendMode.srcIn),
          ),
        ),
        suffixIcon: IconButton(
          icon: SvgPicture.asset(
            _obscurePassword
                ? 'assets/images/Eye.svg'
                : 'assets/images/Eye_Closed.svg',
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(primaryColor, BlendMode.srcIn),
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
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ResetPasswordScreen(),
            ),
          );
        },
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

  Widget _buildPrimaryButton() {
    return SizedBox(
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
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _buildPrimaryButton(),
      ],
    );
  }
}
