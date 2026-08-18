import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/api/api.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import 'dart:async';

class PengajuanCutiScreen extends StatefulWidget {
  const PengajuanCutiScreen({super.key});

  @override
  State<PengajuanCutiScreen> createState() => _PengajuanCutiScreenState();
}

class _PengajuanCutiScreenState extends State<PengajuanCutiScreen> {
  int _selectedTipeCuti = 0; // 0: Tahunan, 1: Sakit, 2: Khusus
  DateTime? _tanggalMulai;
  DateTime? _tanggalSelesai;
  final TextEditingController _alasanController = TextEditingController();
  int _alasanLength = 0;

  PlatformFile? _selectedFile;
  bool _isSubmitting = false;
  double _uploadProgress = 0.0;

  final Color _primaryColor = const Color(0xFF2F3B69);

  // Function untuk memilih tanggal
  Future<void> _selectDate(BuildContext context, bool isMulai) async {
    FocusScope.of(context).unfocus();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(), // Hanya bisa mulai dari hari ini
      lastDate: DateTime(DateTime.now().year + 1),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isMulai) {
          _tanggalMulai = picked;
        } else {
          _tanggalSelesai = picked;
        }
      });
    }
  }

  bool get _isDateRangeInvalid {
    if (_tanggalMulai == null || _tanggalSelesai == null) return false;
    return _tanggalSelesai!.isBefore(_tanggalMulai!);
  }

  bool get _isFormValid {
    return !_isSubmitting &&
        _tanggalMulai != null &&
        _tanggalSelesai != null &&
        !_isDateRangeInvalid &&
        _alasanController.text.trim().isNotEmpty;
  }

  // Function untuk memilih file
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: false,
    );

    if (result != null && result.files.single.size < 5000000) {
      // Max 5MB
      setState(() {
        _selectedFile = result.files.single;
      });
    } else if (result != null) {
      if (mounted) {
        AppSnackbar.warning(context, 'File terlalu besar (maks 5MB)');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _alasanController.addListener(() {
      setState(() {
        _alasanLength = _alasanController.text.length;
      });
    });
  }

  @override
  void dispose() {
    _alasanController.dispose();
    super.dispose();
  }

  Future<void> _saveCuti() async {
    setState(() {
      _isSubmitting = true;
      _uploadProgress = 0.0;
    });

    final List<String> tipeLabels = [
      'Cuti Tahunan',
      'Cuti Sakit',
      'Cuti Khusus',
    ];
    final String tipeLabel = tipeLabels[_selectedTipeCuti];

    final bool hasAttachment =
        _selectedFile != null && _selectedFile!.path != null;

    Timer? simulationTimer;
    if (!hasAttachment) {
      simulationTimer = Timer.periodic(const Duration(milliseconds: 120), (
        timer,
      ) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          if (_uploadProgress < 0.9) {
            _uploadProgress += 0.08;
          }
        });
      });
    }

    try {
      final formData = FormData.fromMap({
        'type': tipeLabel,
        'leave_type_id': _selectedTipeCuti + 1,
        'start_date': _tanggalMulai!.toIso8601String().split('T').first,
        'end_date': _tanggalSelesai!.toIso8601String().split('T').first,
        'reason': _alasanController.text.trim(),
        if (hasAttachment)
          'attachment': await MultipartFile.fromFile(
            _selectedFile!.path!,
            filename: _selectedFile!.name,
          ),
      });

      await Api.dio.post(
        '/leave-requests',
        data: formData,
        onSendProgress: hasAttachment
            ? (sent, total) {
                if (total <= 0) return;
                if (mounted) {
                  setState(() => _uploadProgress = sent / total);
                }
              }
            : null,
      );

      simulationTimer?.cancel();
      if (mounted) setState(() => _uploadProgress = 1.0);

      await Future.delayed(const Duration(milliseconds: 250));

      if (!mounted) return;
      AppSnackbar.success(context, 'Pengajuan cuti berhasil dikirim.');
      Navigator.pop(context, true);
    } on DioException catch (e) {
      simulationTimer?.cancel();

      final data = e.response?.data;
      String message = 'Gagal mengirim pengajuan cuti.';

      if (data is Map) {
        if (data['message'] != null) {
          message = data['message'].toString();
        } else if (data['errors'] is Map) {
          final errors = data['errors'] as Map;
          final errorMessages = errors.values
              .whereType<List>()
              .expand((list) => list)
              .map((e) => e.toString())
              .toList();
          if (errorMessages.isNotEmpty) {
            message = errorMessages.join('\n');
          }
        }
      }

      if (!mounted) return;
      AppSnackbar.error(context, message);
    } finally {
      simulationTimer?.cancel();
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _uploadProgress = 0.0;
        });
      }
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
        title: Text(
          'Pengajuan Cuti',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Card Sisa Cuti dengan Background Gradient
              Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E3A6E), Color(0xFF5163B7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sisa Cuti Tahunan',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFFC5CEE0),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '12 ',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: 'Hari Kerja',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFFC5CEE0),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const Divider(color: Colors.white24, height: 1),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          SvgPicture.asset(
                            'assets/images/Calendar.svg',
                            width: 16,
                            height: 16,
                            colorFilter: const ColorFilter.mode(
                              Color(0xFFC5CEE0),
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Berlaku s/d 31 Des 2026',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFC5CEE0),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 2. Tipe Cuti
              Text(
                'Tipe Cuti',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildTipeCutiItem(
                      index: 0,
                      label: 'Tahunan',
                      svgAsset: 'assets/images/Calendar.svg',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTipeCutiItem(
                      index: 1,
                      label: 'Sakit',
                      svgAsset: 'assets/images/Medical.svg',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTipeCutiItem(
                      index: 2,
                      label: 'Khusus',
                      svgAsset: 'assets/images/seru.svg',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 3. Tanggal Mulai & Tanggal Selesai
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tanggal Mulai',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildDateField(
                          date: _tanggalMulai,
                          onTap: () => _selectDate(context, true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tanggal Selesai',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildDateField(
                          date: _tanggalSelesai,
                          onTap: () => _selectDate(context, false),
                          hasError: _isDateRangeInvalid,
                        ),
                        if (_isDateRangeInvalid) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 12,
                                color: Color(0xFFDC2626),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Harus setelah tanggal mulai',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    color: const Color(0xFFDC2626),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 4. Alasan Cuti
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Alasan Cuti',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$_alasanLength/250',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF9A9A9A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _alasanController,
                maxLines: 4,
                maxLength: 250,
                style: GoogleFonts.plusJakartaSans(fontSize: 14),
                decoration: InputDecoration(
                  hintText:
                      'Jelaskan alasan pengajuan cuti Anda secara detail...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                  ),
                  contentPadding: const EdgeInsets.all(14),
                  counterText:
                      '', // <-- ini yang matiin counter bawaan di bawah field
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _primaryColor),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 5. Lampiran (Opsional)
              Text(
                'Lampiran (Opsional)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickFile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F6FB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFC5CEE0),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                      if (_selectedFile == null) ...[
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 36,
                          color: _primaryColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Klik untuk unggah file \n Format PDF, JPG, PNG (maks 5 MB)',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),
                      ] else ...[
                        Icon(
                          _selectedFile!.extension == 'pdf'
                              ? Icons.description
                              : Icons.image,
                          size: 36,
                          color: _primaryColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '✓ File terpilih',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedFile!.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _selectedFile == null ? _pickFile : null,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 24,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F6FB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFC5CEE0),
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Column(
                              children: [
                                if (_selectedFile == null) ...[
                                  Icon(
                                    Icons.cloud_upload_outlined,
                                    size: 36,
                                    color: _primaryColor,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Klik untuk unggah file \n Format PDF, JPG, PNG (maks 5 MB)',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      height: 1.4,
                                    ),
                                  ),
                                ] else ...[
                                  Icon(
                                    _selectedFile!.extension == 'pdf'
                                        ? Icons.description
                                        : Icons.image,
                                    size: 36,
                                    color: _primaryColor,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '✓ File terpilih',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedFile!.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedFile = null;
                                      });
                                    },
                                    behavior: HitTestBehavior.opaque,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.delete_outline,
                                            size: 14,
                                            color: Color(0xFFDC2626),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Hapus File',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              color: const Color(0xFFDC2626),
                                              fontWeight: FontWeight.w600,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // 6. Tombol Simpan
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isFormValid ? _saveCuti : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                                value: _uploadProgress > 0
                                    ? _uploadProgress
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Simpan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _isFormValid
                                ? Colors.white
                                : Colors.grey.shade500,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Tipe Cuti Card Option
  Widget _buildTipeCutiItem({
    required int index,
    required String label,
    required String svgAsset,
  }) {
    final bool isSelected = _selectedTipeCuti == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTipeCuti = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _primaryColor : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              svgAsset,
              width: 22,
              height: 22,
              colorFilter: ColorFilter.mode(
                isSelected ? _primaryColor : Colors.grey.shade600,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? _primaryColor : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Input Tanggal
  Widget _buildDateField({
    required DateTime? date,
    required VoidCallback onTap,
    bool hasError = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: hasError ? const Color(0xFFFEF2F2) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasError ? const Color(0xFFDC2626) : Colors.grey.shade300,
            width: hasError ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                date != null
                    ? DateFormat('dd/MM/yyyy').format(date)
                    : '/dd/mm/yyyy',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: date != null ? Colors.black : Colors.grey.shade400,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SvgPicture.asset(
              'assets/images/Calendar_Grey.svg',
              width: 18,
              height: 18,
            ),
          ],
        ),
      ),
    );
  }
}
