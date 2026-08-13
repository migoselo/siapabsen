import 'package:flutter/material.dart';
import '../widgets/profile_header.dart';

const Color kNavy = Color(0xFF2E3A6E);
const Color kTextPrimary = Color(0xFF0F172A);
const Color kTextSecondary = Color(0xFF6B7280);
const Color kBorder = Color(0xFFE5E7EB);
const String kFontFamily = 'PlusJakartaSans';

/// TODO: SEMUA data di halaman ini masih DUMMY (kecuali nama & email
/// kalau kamu passing dari user asli). Field-field ini (NIK, golongan,
/// rekening, dll) belum ada di backend/UserModel — perlu ditambahin
/// dulu begitu strukturnya jelas.
class BiodataPage extends StatelessWidget {
  final String userName;
  final String userEmail;

  const BiodataPage({
    super.key,
    required this.userName,
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- Header AppBar-style ---
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Biodata',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: kFontFamily,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: kTextPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),

            // --- Card profil navy ---
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: kNavy,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  ClipOval(child: IdenticonAvatar(username: userName, size: 90.0)),
                  const SizedBox(height: 12),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    userEmail,
                    style: const TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Full time developer', // TODO: dummy
                        style: TextStyle(
                          fontFamily: kFontFamily,
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(Icons.location_on_outlined, size: 14, color: Colors.white70),
                      SizedBox(width: 2),
                      Text(
                        'Kantor Pusat', // TODO: dummy
                        style: TextStyle(
                          fontFamily: kFontFamily,
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionCard(
                    title: 'Informasi Pekerjaan',
                    rows: const [
                      ('ID Karyawan', 'EMP-0231'),
                      ('Nama Panggilan', 'Andi'),
                      ('Departemen', 'Developer'),
                      ('Jabatan', 'Full time developer'),
                      ('Golongan', 'IA'),
                      ('Cabang (Branch)', 'Siap Integrasi'),
                      ('Tipe Karyawan', 'Daily'),
                      ('Tanggal Bergabung', '25 Agustus 2022'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionCard(
                    title: 'Data Pribadi',
                    rows: const [
                      ('NIK', '33303003000'),
                      ('Tempat, Tanggal Lahir', 'Surabaya, 20-09-1990'),
                      ('Jenis Kelamin', 'Laki-laki'),
                      ('Agama', 'Kristen'),
                      ('Golongan Darah', 'AB'),
                      ('Status Pernikahan', 'Menikah'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionCard(
                    title: 'Kontak & Alamat',
                    rows: const [
                      ('No. Hp / Telepon', '081234567890'),
                      ('Email', 'Andi@yahud.com'),
                      ('Alamat Lengkap', '-'),
                      ('Kontak Darurat', '-'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionCard(
                    title: 'Rekening & BPJS',
                    rows: const [
                      ('Nama Bank', '-'),
                      ('No. Rekening', '-'),
                      ('Atas Nama Rekening', '-'),
                      ('Kode PTKP / NPWP', '-'),
                      ('BPJS Ketenagakerjaan', '-'),
                      ('BPJS Kesehatan', '-'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionCard(
                    title: 'Pendidikan & Keluarga',
                    rows: const [
                      ('Pendidikan Terakhir', '-'),
                      ('Institusi / Sekolah', '-'),
                      ('Sertifikasi', '-'),
                      ('Nama Pasangan', '-'),
                      ('Nama Ayah', '-'),
                      ('Nama Ibu', '-'),
                      ('Jumlah Anak', '-'),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<(String, String)> rows;

  const _SectionCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
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
        const SizedBox(height: 4),
        Container(height: 1.5, width: 80, color: kNavy),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: kBorder),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: rows.map((r) => _InfoLine(label: r.$1, value: r.$2)).toList(),
          ),
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: kFontFamily,
                fontSize: 13,
                color: kTextSecondary,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(fontFamily: kFontFamily, fontSize: 13, color: kTextSecondary)),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: kFontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}