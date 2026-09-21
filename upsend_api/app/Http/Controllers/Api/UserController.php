<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class UserController extends Controller
{
    protected function currentTenantId()
    {
        // app('currentTenant') bisa berupa model Tenant atau raw id (sesuai SetTenant middleware)
        $tenant = app()->bound('currentTenant') ? app('currentTenant') : null;
        if (is_object($tenant) && isset($tenant->id)) {
            return $tenant->id;
        }
        if (is_numeric($tenant)) {
            return (int)$tenant;
        }

        return Auth::user()?->tenant_id ?? 1;
    }

    protected function ensureSameTenant(User $user)
    {
        $tenantId = $this->currentTenantId();
        if ($tenantId && ($user->tenant_id !== (int)$tenantId)) {
            abort(404); // hide existence if not in same tenant
        }
    }

    public function index(Request $request)
    {
        // Batasi hasil ke tenant saat ini (jika ada)
        $query = User::with(['homeLocation', 'division', 'shift'])->forTenant();

        if ($request->filled('location_id')) {
            $query->where('home_location_id', $request->location_id);
        }

        if ($request->filled('role')) {
            $query->where('role', $request->role);
        }

        $perPage = $request->input('per_page', 10);
        return response()->json($query->orderBy('name')->paginate($perPage));
    }

    public function store(Request $request)
    {
        $tenantId = $this->currentTenantId();

        // unique email scoped to tenant if tenant active, otherwise global unique
        $emailRule = $tenantId
            ? Rule::unique('users')->where(function ($q) use ($tenantId) {
                $q->where('tenant_id', $tenantId);
            })
            : 'unique:users,email';

        $data = $request->validate([
            'name' => 'required|string|max:255',
            'email' => ['required','email',$emailRule],
            'password' => 'required|string|min:6',
            'no_hp' => 'nullable|string|max:255',
            'role' => 'required|in:admin,karyawan',
            'home_location_id' => 'nullable|exists:locations,id',
            'division_id' => 'nullable|exists:divisions,id',
            'shift_id' => 'nullable|exists:shifts,id',
            ...$this->biodataRules(),
        ]);

        // pastikan client tidak bisa menulis tenant_id langsung (kami set via middleware/trait)
        if (isset($data['tenant_id'])) {
            unset($data['tenant_id']);
        }

        $data['password'] = Hash::make($data['password']);
        $data['tenant_id'] = (int) $tenantId;
        $data['employee_id'] = $this->generateEmployeeId((int) $tenantId);

        $user = User::create($data);

        return response()->json($user->load(['homeLocation', 'division', 'shift']), 201);
    }

    protected function generateEmployeeId(int $tenantId): string
    {
        do {
            $employeeId = 'EMP-' . $tenantId . '-' . now()->format('YmdHis') . '-' . random_int(1000, 9999);
        } while (User::where('tenant_id', $tenantId)->where('employee_id', $employeeId)->exists());

        return $employeeId;
    }

    public function show(User $user)
    {
        $this->ensureSameTenant($user);

        return response()->json($user->load(['homeLocation', 'division', 'shift']));
    }

    public function update(Request $request, User $user)
    {
        $this->ensureSameTenant($user);

        $tenantId = $this->currentTenantId();

        $emailRule = $tenantId
            ? Rule::unique('users')->where(function ($q) use ($tenantId) {
                $q->where('tenant_id', $tenantId);
            })->ignore($user->id)
            : Rule::unique('users')->ignore($user->id);

        $data = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'email' => ['sometimes','required','email',$emailRule],
            'no_hp' => 'nullable|string|max:255',
            'role' => 'sometimes|required|in:admin,karyawan',
            'is_active' => 'sometimes|boolean',
            'division_id' => 'nullable|exists:divisions,id',
            'shift_id' => 'nullable|exists:shifts,id',
            ...$this->biodataRules(),
        ]);

        $user->update($data);

        return response()->json($user->load(['homeLocation', 'division', 'shift']));
    }

    protected function biodataRules(): array
    {
        return [
            'department' => 'nullable|string|max:255',
            'grade' => 'nullable|string|max:255',
            'employee_type' => 'nullable|string|max:255',
            'joined_at' => 'nullable|date',
            'nik' => 'nullable|string|max:255',
            'birth_place' => 'nullable|string|max:255',
            'birth_date' => 'nullable|date',
            'gender' => 'nullable|string|max:50',
            'religion' => 'nullable|string|max:100',
            'blood_type' => 'nullable|string|max:3',
            'marital_status' => 'nullable|string|max:100',
            'address' => 'nullable|string',
            'emergency_contact' => 'nullable|string|max:255',
            'bank_name' => 'nullable|string|max:255',
            'bank_account_number' => 'nullable|string|max:255',
            'bank_account_name' => 'nullable|string|max:255',
            'tax_number' => 'nullable|string|max:255',
            'bpjs_employment' => 'nullable|string|max:255',
            'bpjs_health' => 'nullable|string|max:255',
            'last_education' => 'nullable|string|max:255',
            'education_institution' => 'nullable|string|max:255',
            'certification' => 'nullable|string',
            'spouse_name' => 'nullable|string|max:255',
            'father_name' => 'nullable|string|max:255',
            'mother_name' => 'nullable|string|max:255',
            'children_count' => 'nullable|integer|min:0|max:255',
        ];
    }

    public function transfer(Request $request, User $user)
    {
        $this->ensureSameTenant($user);

        $data = $request->validate([
            'home_location_id' => 'required|exists:locations,id',
        ]);

        $user->update(['home_location_id' => $data['home_location_id']]);

        return response()->json($user->load('homeLocation'));
    }

    public function destroy(User $user)
    {
        $this->ensureSameTenant($user);

        // Soft-nonaktifkan, bukan hard delete, biar histori attendance tetap utuh
        $user->update(['is_active' => false]);

        return response()->json(['message' => 'Karyawan berhasil dinonaktifkan.']);
    }
}