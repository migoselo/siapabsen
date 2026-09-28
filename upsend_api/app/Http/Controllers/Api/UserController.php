<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Support\AdminPermissionCatalog;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class UserController extends Controller
{
    protected function currentTenantId(?Request $request = null)
    {
        $user = Auth::user();
        if (! in_array($user?->role, ['super_admin', 'superadmin'], true)) {
            return $user?->tenant_id ?? 1;
        }

        if ($request?->filled('tenant_id')) {
            return (int) $request->input('tenant_id');
        }

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

    protected function ensureSameTenant(User $user, ?Request $request = null)
    {
        $tenantId = $this->currentTenantId($request);
        if ($tenantId && ($user->tenant_id !== (int)$tenantId)) {
            abort(404); // hide existence if not in same tenant
        }
    }

    public function index(Request $request)
    {
        $tenantId = $this->currentTenantId($request);
        $query = User::with(['homeLocation', 'division', 'shift'])->where('tenant_id', $tenantId);

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
        $tenantId = $this->currentTenantId($request);

        $data = $request->validate([
            'name' => 'required|string|max:255',
            'email' => ['required', 'email'],
            'password' => 'nullable|string|min:6',
            'no_hp' => 'nullable|string|max:255',
            'role' => 'required|in:admin,karyawan',
            'tenant_id' => [
                'sometimes',
                'required',
                'integer',
                Rule::exists('tenants', 'id')->where(fn ($query) => $query->where('id', $tenantId)),
            ],
            'home_location_id' => [
                'nullable',
                Rule::exists('locations', 'id')->where(fn ($query) => $query->where('tenant_id', $tenantId)),
            ],
            'division_id' => [
                'nullable',
                Rule::exists('divisions', 'id')->where(fn ($query) => $query->where('tenant_id', $tenantId)),
            ],
            'shift_id' => [
                'nullable',
                Rule::exists('shifts', 'id')->where(function ($query) use ($tenantId, $request) {
                    $query->where('tenant_id', $tenantId);
                    if ($request->filled('division_id')) {
                        $query->where('division_id', $request->input('division_id'));
                    } else {
                        $query->whereNull('division_id');
                    }
                }),
            ],
            ...$this->biodataRules(),
        ]);

        // pastikan client tidak bisa menulis tenant_id langsung (kami set via middleware/trait)
        if (isset($data['tenant_id'])) {
            unset($data['tenant_id']);
        }

        $existingUser = User::where('tenant_id', $tenantId)
            ->where('email', $data['email'])
            ->first();

        if ($existingUser) {
            if ($existingUser->is_active) {
                return response()->json([
                    'message' => 'Email tersebut sudah terdaftar pada akun aktif.',
                ], 422);
            }

            $invitationToken = Str::random(64);
            $existingUser->update([
                'name' => $data['name'],
                'no_hp' => $data['no_hp'] ?? null,
                'home_location_id' => $data['home_location_id'] ?? null,
                'division_id' => $data['division_id'] ?? null,
                'shift_id' => $data['shift_id'] ?? null,
                'role' => $data['role'],
                'invitation_token' => hash('sha256', $invitationToken),
                'invitation_expires_at' => now()->addHours(48),
                'invited_at' => now(),
            ]);

            $activationUrl = rtrim((string) config('app.frontend_url', env('FRONTEND_URL', 'http://localhost:5173')), '/')
                . '/aktivasi-akun?token=' . urlencode($invitationToken);
            app(\App\Services\EmailDeliveryService::class)->send(
                $existingUser->email,
                'Undangan Aktivasi Akun Upsend',
                "Halo {$existingUser->name},\n\nBerikut link aktivasi akun Anda:\n{$activationUrl}\n\nLink berlaku 48 jam.",
            );

            return response()->json([
                'message' => 'Akun belum aktif. Undangan aktivasi telah dikirim ulang ke email karyawan.',
                'user' => $existingUser->load(['homeLocation', 'division', 'shift']),
            ]);
        }

        $invitationToken = Str::random(64);
        $data['password'] = Hash::make(Str::random(40));
        $data['tenant_id'] = (int) $tenantId;
        $data['employee_id'] = User::generateEmployeeId((int) $tenantId);
        $data['is_active'] = false;
        $data['invitation_token'] = hash('sha256', $invitationToken);
        $data['invitation_expires_at'] = now()->addHours(48);
        $data['invited_at'] = now();

        $user = User::create($data);

        $activationUrl = rtrim((string) config('app.frontend_url', env('FRONTEND_URL', 'http://localhost:5173')), '/')
            . '/aktivasi-akun?token=' . urlencode($invitationToken);
        app(\App\Services\EmailDeliveryService::class)->send(
            $user->email,
            'Aktivasi Akun Upsend',
            "Halo {$user->name},\n\nAdmin telah membuat akun Anda. Aktifkan akun melalui link berikut:\n{$activationUrl}\n\nLink berlaku 48 jam.",
        );

        return response()->json([
            'message' => 'Karyawan berhasil dibuat. Link aktivasi telah dikirim ke email karyawan.',
            'user' => $user->load(['homeLocation', 'division', 'shift']),
        ], 201);
    }

    public function show(User $user)
    {
        $this->ensureSameTenant($user);

        return response()->json($user->load(['homeLocation', 'division', 'shift']));
    }

    public function resendInvitation(User $user)
    {
        $this->ensureSameTenant($user);

        if ($user->is_active) {
            return response()->json(['message' => 'Akun karyawan sudah aktif.'], 422);
        }

        $token = Str::random(64);
        $user->update([
            'invitation_token' => hash('sha256', $token),
            'invitation_expires_at' => now()->addHours(48),
            'invited_at' => now(),
        ]);
        $activationUrl = rtrim((string) env('FRONTEND_URL', 'http://localhost:5173'), '/')
            . '/aktivasi-akun?token=' . urlencode($token);
        app(\App\Services\EmailDeliveryService::class)->send(
            $user->email,
            'Undangan Aktivasi Akun Upsend',
            "Halo {$user->name},\n\nBerikut link aktivasi akun Anda:\n{$activationUrl}\n\nLink berlaku 48 jam.",
        );

        return response()->json(['message' => 'Undangan aktivasi berhasil dikirim ulang.']);
    }

    public function update(Request $request, User $user)
    {
        $this->ensureSameTenant($user, $request);

        $tenantId = $this->currentTenantId($request);

        $emailRule = $tenantId
            ? Rule::unique('users')->where(function ($q) use ($tenantId) {
                $q->where('tenant_id', $tenantId);
            })->ignore($user->id)
            : Rule::unique('users')->ignore($user->id);

        $data = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'email' => ['sometimes', 'required', 'email', $emailRule],
            'no_hp' => 'nullable|string|max:255',
            'role' => 'sometimes|required|in:admin,karyawan',
            'is_active' => 'sometimes|boolean',
            'home_location_id' => [
                'sometimes',
                'nullable',
                Rule::exists('locations', 'id')->where(fn ($query) => $query->where('tenant_id', $tenantId)),
            ],
            'permissions' => ['sometimes', 'required_if:role,admin', 'array'],
            'permissions.*' => ['required', 'string', Rule::in(AdminPermissionCatalog::ids())],
            'division_id' => [
                'nullable',
                Rule::exists('divisions', 'id')->where(fn ($query) => $query->where('tenant_id', $tenantId)),
            ],
            'shift_id' => [
                'nullable',
                Rule::exists('shifts', 'id')->where(fn ($query) => $query->where('tenant_id', $tenantId)),
            ],
            ...$this->biodataRules(),
        ]);

        if (array_key_exists('role', $data) && $data['role'] !== $user->role) {
            abort_unless(in_array(Auth::user()?->role, ['super_admin', 'superadmin'], true), 403);
            if ($data['role'] === 'admin') {
                $permissions = array_values(array_unique($data['permissions'] ?? []));
                if (! in_array('dashboard.view', $permissions, true)) $permissions[] = 'dashboard.view';
                $data['permissions'] = $permissions;
            } else {
                $data['permissions'] = null;
            }
        } elseif (isset($data['permissions'])) {
            abort_unless(in_array(Auth::user()?->role, ['super_admin', 'superadmin'], true), 403);
            abort_unless($user->role === 'admin', 422, 'Hak akses hanya dapat diberikan kepada admin perusahaan.');
            $permissions = array_values(array_unique($data['permissions']));
            if (! in_array('dashboard.view', $permissions, true)) $permissions[] = 'dashboard.view';
            $data['permissions'] = $permissions;
        }

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
        $this->ensureSameTenant($user, $request);
        $tenantId = $this->currentTenantId($request);

        $data = $request->validate([
            'home_location_id' => [
                'required',
                Rule::exists('locations', 'id')->where(fn ($query) => $query->where('tenant_id', $tenantId)),
            ],
        ]);

        $user->update(['home_location_id' => $data['home_location_id']]);

        return response()->json($user->load('homeLocation'));
    }

    public function destroy(Request $request, User $user)
    {
        $this->ensureSameTenant($user, $request);

        // Soft-nonaktifkan, bukan hard delete, biar histori attendance tetap utuh
        $user->update(['is_active' => false]);

        return response()->json(['message' => 'Karyawan berhasil dinonaktifkan.']);
    }
}
