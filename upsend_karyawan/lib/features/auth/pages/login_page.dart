import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:upsend_karyawan/features/auth/bloc/auth_bloc.dart';
import 'package:upsend_karyawan/core/widgets/custom_snackbar.dart';
import 'package:upsend_karyawan/features/auth/pages/reset_password_screen.dart';
import 'package:upsend_karyawan/core/api/api.dart';
import 'package:flutter/services.dart';

enum LoginType { email, employeeId, phone }

class LocationItem {
  final int id;
  final String name;

  LocationItem({required this.id, required this.name});

  factory LocationItem.fromJson(Map<String, dynamic> json) {
    return LocationItem(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }
}

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

  final FocusNode _branchFocusNode = FocusNode();

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

  // Batas panjang nomor telepon (tanpa kode negara +62)
  static const int _phoneMinLength = 9;
  static const int _phoneMaxLength = 15;

  // State untuk data Kantor Cabang Dinamis
  List<LocationItem> _locations = [];
  LocationItem? _selectedLocation;
  bool _isLoadingLocations = false;

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
    _fetchLocationsFromBackend();

    _emailController.addListener(_onFieldChanged);
    _employeeIdController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
    _companyController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() => setState(() {});

  String? _locationsFetchError;

  Future<void> _fetchLocationsFromBackend() async {
    setState(() {
      _isLoadingLocations = true;
      _locationsFetchError = null;
    });

    try {
      final response = await Api.dio.get('/locations/public');
      if (response.statusCode == 200 && response.data != null) {
        final List dynamicList = response.data is List
            ? response.data
            : (response.data['data'] ?? []);

        setState(() {
          _locations = dynamicList
              .map((item) => LocationItem.fromJson(item))
              .where((loc) => loc.name.trim().isNotEmpty && loc.name != '0')
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Gagal memuat daftar kantor cabang: $e');
      if (mounted) {
        setState(() {
          _locationsFetchError = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocations = false;
        });
      }
    }
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

    _emailController.removeListener(_onFieldChanged);
    _employeeIdController.removeListener(_onFieldChanged);
    _phoneController.removeListener(_onFieldChanged);
    _passwordController.removeListener(_onFieldChanged);
    _companyController.removeListener(_onFieldChanged);

    _emailController.dispose();
    _companyController.dispose();
    _employeeIdController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _branchFocusNode.dispose();
    super.dispose();
  }

  String _getLoginIdentifier() {
    switch (_currentLoginType) {
      case LoginType.email:
        return _emailController.text.trim();
      case LoginType.employeeId:
        return _employeeIdController.text.trim();
      case LoginType.phone:
        return _phoneController.text.trim();
    }
  }

  bool get _isFormFilled {
    final identifier = _getLoginIdentifier();
    final password = _passwordController.text;

    if (identifier.trim().isEmpty || password.trim().isEmpty) return false;

    if (_currentLoginType == LoginType.employeeId &&
        _selectedLocation == null &&
        _companyController.text.trim().isEmpty) {
      return false;
    }

    return true;
  }

  void _login() {
    final identifier = _getLoginIdentifier();
    final password = _passwordController.text;

    final formatError = _validateIdentifierFormat(identifier);
    if (formatError != null) {
      AppSnackbar.warning(context, formatError);
      return;
    }

    if (password.length < 6) {
      AppSnackbar.warning(context, 'Password minimal 6 karakter!');
      return;
    }

    context.read<AuthBloc>().add(
      AuthLoginRequested(noHp: identifier, password: password),
    );
  }

  String? _validateIdentifierFormat(String identifier) {
    switch (_currentLoginType) {
      case LoginType.email:
        if (!_isValidEmail(identifier)) {
          return 'Format email tidak valid!';
        }
        return null;

      case LoginType.employeeId:
        final employeeId = _employeeIdController.text.trim();
        if (employeeId.isEmpty) {
          return 'ID karyawan wajib diisi!';
        }
        return null;

      case LoginType.phone:
        if (!_isValidPhone(identifier)) {
          return 'Format nomor telepon tidak valid! Gunakan angka saja, $_phoneMinLength-$_phoneMaxLength digit.';
        }
        return null;
    }
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    final regex = RegExp('^[0-9]{$_phoneMinLength,$_phoneMaxLength}\$');
    return regex.hasMatch(phone);
  }

  String? get _phoneErrorText {
    final len = _phoneController.text.trim().length;
    if (len == 0) return null;
    if (len < _phoneMinLength) {
      return 'Nomor telepon minimal $_phoneMinLength digit';
    }
    return null;
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
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: selectorBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final selectedIndex = options.indexWhere(
            (option) => option.$1 == _currentLoginType,
          );
          final itemWidth = constraints.maxWidth / options.length;

          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                left: selectedIndex * itemWidth,
                top: 0,
                bottom: 0,
                width: itemWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x140F172A),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (final option in options)
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_currentLoginType != option.$1) {
                            setState(() => _currentLoginType = option.$1);
                          }
                        },
                        child: Container(
                          alignment: Alignment.center,
                          color: Colors.transparent,
                          child: Text(
                            option.$2,
                            textAlign: TextAlign.center,
                            style: _jakartaStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _currentLoginType == option.$1
                                  ? primaryColor
                                  : subtitleColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
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
            _buildBranchDropdownField(),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 50,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(_phoneMaxLength),
                    ],
                    errorText: _phoneErrorText,
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

  Widget _buildBranchDropdownField() {
    if (_isLoadingLocations) {
      return Container(
        height: 50,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Memuat kantor cabang...',
              style: _jakartaStyle(color: subtitleColor, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_locationsFetchError != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gagal memuat kantor cabang:',
              style: _jakartaStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _locationsFetchError!,
              style: _jakartaStyle(
                fontSize: 11,
                color: const Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _fetchLocationsFromBackend,
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Text(
                'Coba lagi',
                style: _jakartaStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<LocationItem>(
          displayStringForOption: (LocationItem option) => option.name,
          textEditingController: _companyController,
          focusNode: _branchFocusNode,
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return _locations;
            }
            return _locations.where((LocationItem option) {
              return option.name.toLowerCase().contains(
                textEditingValue.text.toLowerCase(),
              );
            });
          },
          onSelected: (LocationItem selection) {
            setState(() {
              _selectedLocation = selection;
              _companyController.text = selection.name;
            });
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              style: _jakartaStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Pilih atau cari kantor cabang',
                hintStyle: _jakartaStyle(color: subtitleColor, fontSize: 14),
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Icon(
                    Icons.business_rounded,
                    color: subtitleColor,
                    size: 20,
                  ),
                ),
                suffixIcon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: subtitleColor,
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
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: options.length > 3 ? 200 : null,
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: selectorBackground),
                    itemBuilder: (BuildContext context, int index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        dense: true,
                        title: Text(
                          option.name,
                          style: _jakartaStyle(fontSize: 14),
                        ),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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
    List<TextInputFormatter>? inputFormatters,
    String? errorText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: _jakartaStyle(fontSize: 14),
      scrollPadding: const EdgeInsets.all(20),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: _jakartaStyle(color: subtitleColor, fontSize: 14),
        errorText: errorText,
        errorStyle: _jakartaStyle(
          fontSize: 11.5,
          color: const Color(0xFFDC2626),
        ),
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
        errorBorder: OutlineInputBorder(
          borderRadius: isPhonePrefix
              ? const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                )
              : BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDC2626)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: isPhonePrefix
              ? const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                )
              : BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
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
                ? 'assets/images/Eye_Closed.svg'
                : 'assets/images/Eye.svg',
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
            MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
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
          final canSubmit = _isFormFilled && !isLoading;

          return ElevatedButton(
            onPressed: canSubmit ? _login : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              disabledBackgroundColor: primaryColor.withOpacity(0.4),
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
    return Column(children: [_buildPrimaryButton()]);
  }
}
