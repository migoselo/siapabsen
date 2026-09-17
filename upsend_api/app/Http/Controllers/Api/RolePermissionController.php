<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\RolePermission;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class RolePermissionController extends Controller
{
    private const CATALOG = [
        ['id' => 'ess_profile_view', 'label' => 'Lihat Profil Mandiri', 'group' => 'Profil & Kepegawaian', 'area' => 'ess'],
        ['id' => 'ess_profile_edit', 'label' => 'Ajukan Perubahan Data Pribadi', 'group' => 'Profil & Kepegawaian', 'area' => 'ess'],
        ['id' => 'ess_payslip_download', 'label' => 'Unduh Slip Gaji Digital', 'group' => 'Profil & Kepegawaian', 'area' => 'ess'],
        ['id' => 'ess_clock_in_out', 'label' => 'Clock-in / Clock-out', 'group' => 'Presensi, Cuti & Lembur', 'area' => 'ess'],
        ['id' => 'ess_leave_request', 'label' => 'Pengajuan Cuti dan Izin', 'group' => 'Presensi, Cuti & Lembur', 'area' => 'ess'],
        ['id' => 'ess_overtime_history', 'label' => 'Lihat Riwayat Lembur', 'group' => 'Presensi, Cuti & Lembur', 'area' => 'ess'],
        ['id' => 'adm_emp_view', 'label' => 'Lihat Data Karyawan', 'group' => 'Manajemen Karyawan', 'area' => 'admin'],
        ['id' => 'adm_emp_add', 'label' => 'Tambah Karyawan', 'group' => 'Manajemen Karyawan', 'area' => 'admin'],
        ['id' => 'adm_emp_edit', 'label' => 'Edit Data Karyawan', 'group' => 'Manajemen Karyawan', 'area' => 'admin'],
        ['id' => 'adm_payroll_view', 'label' => 'Lihat Payroll', 'group' => 'Payroll', 'area' => 'admin'],
        ['id' => 'adm_payroll_approve', 'label' => 'Finalisasi Payroll', 'group' => 'Payroll', 'area' => 'admin'],
        ['id' => 'adm_kpi_evaluate', 'label' => 'Evaluasi Kinerja', 'group' => 'KPI & Performance', 'area' => 'admin'],
    ];

    public function index()
    {
        $roles = User::query()
            ->select('role')
            ->selectRaw('COUNT(*) as user_count')
            ->whereNotNull('role')
            ->groupBy('role')
            ->orderBy('role')
            ->get();

        $permissions = RolePermission::all()->keyBy(fn ($item) => $item->role . ':' . $item->permission);

        return response()->json($roles->map(function ($role) use ($permissions) {
            $items = collect(self::CATALOG)->map(function ($item) use ($role, $permissions) {
                $saved = $permissions->get($role->role . ':' . $item['id']);
                return [...$item, 'checked' => $saved?->enabled ?? false];
            });

            return [
                'id' => $role->role,
                'name' => ucwords(str_replace('_', ' ', $role->role)),
                'user_count' => (int) $role->user_count,
                'permissions' => $items->values(),
            ];
        }));
    }

    public function update(Request $request, string $role)
    {
        abort_unless(User::where('role', $role)->exists(), 404);

        $data = $request->validate([
            'permissions' => ['required', 'array'],
            'permissions.*.id' => ['required', 'string'],
            'permissions.*.checked' => ['required', 'boolean'],
        ]);

        DB::transaction(function () use ($role, $data) {
            foreach ($data['permissions'] as $permission) {
                if (! collect(self::CATALOG)->contains('id', $permission['id'])) continue;
                RolePermission::updateOrCreate(
                    ['role' => $role, 'permission' => $permission['id']],
                    ['enabled' => $permission['checked']],
                );
            }
        });

        return response()->json(['message' => 'Hak akses berhasil diperbarui.']);
    }
}
