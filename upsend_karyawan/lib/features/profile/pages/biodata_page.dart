import 'package:flutter/material.dart';
import '../widgets/profile_header.dart';
import '../../auth/models/user_model.dart';

const Color kNavy = Color(0xFF2E3A6E);
const Color kTextPrimary = Color(0xFF0F172A);
const Color kTextSecondary = Color(0xFF6B7280);
const Color kBorder = Color(0xFFE5E7EB);
const String kFontFamily = 'PlusJakartaSans';

String _birthInfo(UserModel user) {
  final place = user.biodataValue('birth_place');
  final date = user.biodataValue('birth_date');
  if (place == '-' && date == '-') return '-';
  if (date == '-') return place;
  if (place == '-') return date;
  return '$place, $date';
}

class BiodataPage extends StatelessWidget {
  final UserModel user;

  const BiodataPage({super.key, required this.user});

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
                  ClipOval(
                    child: IdenticonAvatar(username: user.name, size: 90.0),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: const TextStyle(
                      fontFamily: kFontFamily,
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        user.role.isNotEmpty ? user.role : '-',
                        style: const TextStyle(
                          fontFamily: kFontFamily,
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Colors.white70,
                      ),
                      SizedBox(width: 2),
                      Text(
                        user.homeLocationName ?? '-',
                        style: const TextStyle(
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
                    rows: [
                      ('ID Karyawan', user.employeeCode),
                      ('Nama Lengkap', user.name),
                      ('Departemen', user.biodataValue('department')),
                      ('Jabatan', user.role.isNotEmpty ? user.role : '-'),
                      ('Golongan', user.biodataValue('grade')),
                      ('Cabang (Branch)', user.homeLocationName ?? '-'),
                      ('Tipe Karyawan', user.biodataValue('employee_type')),
                      ('Tanggal Bergabung', user.biodataValue('joined_at')),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionCard(
                    title: 'Data Pribadi',
                    rows: [
                      ('NIK', user.biodataValue('nik')),
                      ('Tempat, Tanggal Lahir', _birthInfo(user)),
                      ('Jenis Kelamin', user.biodataValue('gender')),
                      ('Agama', user.biodataValue('religion')),
                      ('Golongan Darah', user.biodataValue('blood_type')),
                      (
                        'Status Pernikahan',
                        user.biodataValue('marital_status'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionCard(
                    title: 'Kontak & Alamat',
                    rows: [
                      ('No. Hp / Telepon', user.noHp),
                      ('Email', user.email),
                      ('Alamat Lengkap', user.biodataValue('address')),
                      (
                        'Kontak Darurat',
                        user.biodataValue('emergency_contact'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionCard(
                    title: 'Rekening & BPJS',
                    rows: [
                      ('Nama Bank', user.biodataValue('bank_name')),
                      (
                        'No. Rekening',
                        user.biodataValue('bank_account_number'),
                      ),
                      (
                        'Atas Nama Rekening',
                        user.biodataValue('bank_account_name'),
                      ),
                      ('Kode PTKP / NPWP', user.biodataValue('tax_number')),
                      (
                        'BPJS Ketenagakerjaan',
                        user.biodataValue('bpjs_employment'),
                      ),
                      ('BPJS Kesehatan', user.biodataValue('bpjs_health')),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionCard(
                    title: 'Pendidikan & Keluarga',
                    rows: [
                      (
                        'Pendidikan Terakhir',
                        user.biodataValue('last_education'),
                      ),
                      (
                        'Institusi / Sekolah',
                        user.biodataValue('education_institution'),
                      ),
                      ('Sertifikasi', user.biodataValue('certification')),
                      ('Nama Pasangan', user.biodataValue('spouse_name')),
                      ('Nama Ayah', user.biodataValue('father_name')),
                      ('Nama Ibu', user.biodataValue('mother_name')),
                      ('Jumlah Anak', user.biodataValue('children_count')),
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
            children: rows
                .map((r) => _InfoLine(label: r.$1, value: r.$2))
                .toList(),
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
          const Text(
            ': ',
            style: TextStyle(
              fontFamily: kFontFamily,
              fontSize: 13,
              color: kTextSecondary,
            ),
          ),
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
