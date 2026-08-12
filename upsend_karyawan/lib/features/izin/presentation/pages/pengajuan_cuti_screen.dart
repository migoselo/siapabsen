import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/cuti_model.dart';

class PengajuanCutiScreen extends StatefulWidget {
  const PengajuanCutiScreen({super.key});

  @override
  State<PengajuanCutiScreen> createState() => _PengajuanCutiScreenState();
}

class _PengajuanCutiScreenState extends State<PengajuanCutiScreen> {
  int _selectedTipeCuti = 0; // 0: Tahunan, 1: Sakit, 2: Penting
  DateTime? _tanggalMulai;
  DateTime? _tanggalSelesai;
  final TextEditingController _alasanController = TextEditingController();
  PlatformFile? _selectedFile; // Untuk menyimpan file yang dipilih

  final Color _primaryColor = const Color(0xFF2E3A6E);

  // Function untuk memilih tanggal
  Future<void> _selectDate(BuildContext context, bool isMulai) async {
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File terlalu besar (max 5MB)')),
        );
      }
    }
  }

  @override
  void dispose() {
    _alasanController.dispose();
    super.dispose();
  }

  void _saveCuti() {
    if (_tanggalMulai == null || _tanggalSelesai == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal mulai dan selesai.')),
      );
      return;
    }

    if (_tanggalSelesai!.isBefore(_tanggalMulai!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal selesai harus setelah tanggal mulai.'),
        ),
      );
      return;
    }

    if (_alasanController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi alasan cuti terlebih dahulu.')),
      );
      return;
    }

    final List<String> tipeLabels = [
      'Cuti Tahunan',
      'Cuti Sakit',
      'Cuti Penting',
    ];
    final String tipeLabel = tipeLabels[_selectedTipeCuti];
    final String dateRange =
        '${DateFormat('dd MMM yyyy', 'id_ID').format(_tanggalMulai!)} - ${DateFormat('dd MMM yyyy', 'id_ID').format(_tanggalSelesai!)}';
    final int durationDays =
        _tanggalSelesai!.difference(_tanggalMulai!).inDays + 1;

    final newCuti = CutiModel(
      svgPath: _selectedTipeCuti == 1
          ? 'assets/images/Medical.svg'
          : _selectedTipeCuti == 2
          ? 'assets/images/seru.svg'
          : 'assets/images/Calendar.svg',
      iconBgColor: _selectedTipeCuti == 1
          ? const Color(0xFFFFF7E6)
          : _selectedTipeCuti == 2
          ? const Color(0xFFFFEAEA)
          : const Color(0xFFE8EEFF),
      title: tipeLabel,
      subtitle: _alasanController.text.trim(),
      statusText: 'DIPROSES',
      statusColor: const Color(0xFFFFF8E1),
      statusTextColor: const Color(0xFFE2B93B),
      dateRange: dateRange,
      duration: '$durationDays Hari',
    );

    Navigator.pop(context, newCuti);
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
      body: SingleChildScrollView(
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
                    label: 'Penting',
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
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 4. Alasan Cuti
            Text(
              'Alasan Cuti',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _alasanController,
              maxLines: 4,
              style: GoogleFonts.plusJakartaSans(fontSize: 14),
              decoration: InputDecoration(
                hintText:
                    'Jelaskan alasan pengajuan cuti Anda secara detail...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: Colors.grey.shade400,
                  fontSize: 13,
                ),
                contentPadding: const EdgeInsets.all(14),
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
                        'Klik untuk unggah dokumen pendukung\n(PDF, JPG, PNG)',
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
                        child: Text(
                          'Ganti File',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: _primaryColor,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
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
                onPressed: _saveCuti,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Simpan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
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
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                date != null
                    ? DateFormat('dd/MM/yyyy').format(date)
                    : 'mm/dd/yyyy',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: date != null ? Colors.black : Colors.grey.shade400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
