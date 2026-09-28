<?php

namespace App\Support;

class AdminPermissionCatalog
{
    public static function all(): array
    {
        return [
            ['id' => 'dashboard.view', 'label' => 'Dashboard', 'description' => 'Ringkasan perusahaan dan presensi hari ini.', 'grants' => ['dashboard.view', 'locations.view']],
            ['id' => 'locations.access', 'label' => 'Lokasi kerja', 'description' => 'Lihat dan kelola lokasi serta koordinat.', 'grants' => ['locations.view', 'locations.manage']],
            ['id' => 'employees.access', 'label' => 'Karyawan', 'description' => 'Lihat, tambah, ubah, dan nonaktifkan akun karyawan.', 'grants' => ['employees.view', 'employees.create', 'employees.update', 'employees.deactivate', 'employees.invite', 'employees.transfer', 'locations.view', 'structure.view']],
            ['id' => 'attendance.access', 'label' => 'Absensi', 'description' => 'Lihat dan tinjau data absensi.', 'grants' => ['attendance.view', 'attendance.review', 'locations.view']],
            ['id' => 'requests.access', 'label' => 'Izin, cuti, dan lembur', 'description' => 'Lihat dan tinjau pengajuan.', 'grants' => ['requests.view', 'requests.review', 'locations.view']],
            ['id' => 'payroll.access', 'label' => 'Payroll', 'description' => 'Lihat dan kelola penggajian.', 'grants' => ['payroll.view', 'payroll.manage', 'locations.view']],
            ['id' => 'structure.access', 'label' => 'Divisi dan shift', 'description' => 'Lihat dan kelola struktur kerja.', 'grants' => ['structure.view', 'structure.manage', 'locations.view', 'employees.view']],
        ];
    }

    public static function ids(): array
    {
        return array_column(self::all(), 'id');
    }

    public static function implied(): array
    {
        $permissions = [
            'locations.access' => ['locations.view', 'locations.manage'],
            'employees.access' => ['employees.view', 'employees.create', 'employees.update', 'employees.deactivate', 'employees.invite', 'employees.transfer'],
            'attendance.access' => ['attendance.view', 'attendance.review'],
            'requests.access' => ['requests.view', 'requests.review'],
            'payroll.access' => ['payroll.view', 'payroll.manage'],
            'structure.access' => ['structure.view', 'structure.manage'],
            'locations.manage' => ['locations.view'],
            'employees.create' => ['employees.view'],
            'employees.update' => ['employees.view'],
            'employees.deactivate' => ['employees.view'],
            'employees.invite' => ['employees.view'],
            'employees.transfer' => ['employees.view'],
            'attendance.review' => ['attendance.view'],
            'requests.review' => ['requests.view'],
            'payroll.manage' => ['payroll.view'],
            'structure.manage' => ['structure.view'],
        ];

        foreach (self::all() as $module) {
            $permissions[$module['id']] = $module['grants'];
        }

        return $permissions;
    }

}