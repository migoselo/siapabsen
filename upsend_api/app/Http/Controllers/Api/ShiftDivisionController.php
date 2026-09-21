<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Division;
use App\Models\Shift;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\Rule;

class ShiftDivisionController extends Controller
{
    private function tenantId(?Request $request = null): int
    {
        $user = Auth::user();
        if ($request?->filled('tenant_id') && in_array($user?->role, ['super_admin', 'superadmin'], true)) {
            return (int) $request->integer('tenant_id');
        }

        return (int) ($user?->tenant_id ?? 1);
    }

    public function indexTenants()
    {
        $query = \App\Models\Tenant::query()->orderBy('name');
        if (!in_array(Auth::user()?->role, ['super_admin', 'superadmin'], true)) {
            $query->whereKey(Auth::user()?->tenant_id ?? 1);
        }

        return response()->json($query->withCount('users')->get());
    }

    public function indexDivisions(Request $request)
    {
        return response()->json(Division::withCount('employees')->forTenant($this->tenantId($request))->orderBy('name')->get());
    }

    public function storeDivision(Request $request)
    {
        $tenantId = $this->tenantId($request);
        $data = $request->validate([
            'name' => ['required', 'string', 'max:255', Rule::unique('divisions')->where(fn ($q) => $q->where('tenant_id', $tenantId))],
            'description' => 'nullable|string',
            'is_active' => 'sometimes|boolean',
        ]);
        $data['tenant_id'] = $tenantId;
        return response()->json(Division::create($data), 201);
    }

    public function updateDivision(Request $request, Division $division)
    {
        $this->ensureTenant($division->tenant_id);
        $data = $request->validate(['name' => 'sometimes|required|string|max:255', 'description' => 'nullable|string', 'is_active' => 'sometimes|boolean']);
        $division->update($data);
        return response()->json($division->loadCount('employees'));
    }

    public function destroyDivision(Division $division)
    {
        $this->ensureTenant($division->tenant_id);
        if ($division->employees()->exists()) {
            return response()->json(['message' => 'Divisi masih digunakan oleh karyawan.'], 422);
        }
        $division->delete();
        return response()->noContent();
    }

    public function indexShifts(Request $request)
    {
        return response()->json(Shift::with('division')->forTenant($this->tenantId($request))->orderBy('name')->get());
    }

    public function storeShift(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'division_id' => 'nullable|exists:divisions,id',
            'work_start_time' => 'required|date_format:H:i',
            'work_end_time' => 'required|date_format:H:i',
            'is_active' => 'sometimes|boolean',
        ]);
        $data['tenant_id'] = $this->tenantId($request);
        $this->ensureDivisionTenant($data['division_id'] ?? null, $tenantId);
        return response()->json(Shift::create($data)->load('division'), 201);
    }

    public function updateShift(Request $request, Shift $shift)
    {
        $this->ensureTenant($shift->tenant_id);
        $data = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'division_id' => 'nullable|exists:divisions,id',
            'work_start_time' => 'sometimes|required|date_format:H:i',
            'work_end_time' => 'sometimes|required|date_format:H:i',
            'is_active' => 'sometimes|boolean',
        ]);
        $this->ensureDivisionTenant($data['division_id'] ?? $shift->division_id, $shift->tenant_id);
        $shift->update($data);
        return response()->json($shift->load('division'));
    }

    public function destroyShift(Shift $shift)
    {
        $this->ensureTenant($shift->tenant_id);
        if ($shift->employees()->exists()) {
            return response()->json(['message' => 'Shift masih digunakan oleh karyawan.'], 422);
        }
        $shift->delete();
        return response()->noContent();
    }

    private function ensureTenant(?int $tenantId): void
    {
        abort_unless((int) $tenantId === $this->tenantId(), 404);
    }

    private function ensureDivisionTenant(?int $divisionId, int $tenantId): void
    {
        if ($divisionId !== null) {
            abort_unless(Division::forTenant($tenantId)->whereKey($divisionId)->exists(), 422, 'Divisi tidak ditemukan.');
        }
    }
}