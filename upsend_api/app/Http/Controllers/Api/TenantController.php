<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Tenant;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class TenantController extends Controller
{
    public function index(): mixed
    {
        $query = Tenant::query()
            ->withCount(['users', 'locations'])
            ->orderBy('name');

        if (!$this->isSuperAdmin()) {
            $query->whereKey(Auth::user()?->tenant_id ?? 1);
        }

        return response()->json($query->get());
    }

    public function store(Request $request): mixed
    {
        $this->requireSuperAdmin();

        $data = $request->validate([
            'name' => 'required|string|max:255',
            'slug' => ['nullable', 'string', 'max:255', 'alpha_dash', Rule::unique('tenants', 'slug')],
            'status' => 'sometimes|in:active,inactive',
            'alpha_deduction_per_day' => 'sometimes|numeric|min:0',
        ]);

        $data['slug'] = $data['slug'] ?? Str::slug($data['name']);
        if (Tenant::where('slug', $data['slug'])->exists()) {
            return response()->json(['message' => 'Slug perusahaan sudah digunakan.'], 422);
        }

        return response()->json(Tenant::create($data), 201);
    }

    public function show(Tenant $tenant): mixed
    {
        $this->ensureVisible($tenant);

        return response()->json($tenant->loadCount(['users', 'locations']));
    }

    public function update(Request $request, Tenant $tenant): mixed
    {
        $this->requireSuperAdmin();
        $this->ensureVisible($tenant);

        $data = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'slug' => [
                'sometimes',
                'required',
                'string',
                'max:255',
                'alpha_dash',
                Rule::unique('tenants', 'slug')->ignore($tenant->id),
            ],
            'status' => 'sometimes|in:active,inactive',
            'alpha_deduction_per_day' => 'sometimes|numeric|min:0',
        ]);

        $tenant->update($data);

        return response()->json($tenant->loadCount(['users', 'locations']));
    }

    public function destroy(Tenant $tenant): mixed
    {
        $this->requireSuperAdmin();
        $this->ensureVisible($tenant);

        if ($tenant->users()->exists() || $tenant->locations()->exists()) {
            return response()->json([
                'message' => 'Perusahaan masih memiliki karyawan atau lokasi. Nonaktifkan perusahaan terlebih dahulu.',
            ], 422);
        }

        $tenant->delete();

        return response()->noContent();
    }

    private function isSuperAdmin(): bool
    {
        return in_array(Auth::user()?->role, ['super_admin', 'superadmin'], true);
    }

    private function requireSuperAdmin(): void
    {
        abort_unless($this->isSuperAdmin(), 403, 'Hanya Super Admin yang dapat mengelola perusahaan.');
    }

    private function ensureVisible(Tenant $tenant): void
    {
        if (!$this->isSuperAdmin()) {
            abort_unless((int) $tenant->id === (int) (Auth::user()?->tenant_id ?? 1), 404);
        }
    }
}
