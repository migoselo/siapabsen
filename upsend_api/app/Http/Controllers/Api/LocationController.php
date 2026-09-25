<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Location;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class LocationController extends Controller
{
    public function index(Request $request)
    {
        $query = Location::query()->orderBy('name');
        $tenantId = $this->tenantId($request);

        if ($tenantId) {
            $query->where('tenant_id', $tenantId);
        }

        return response()->json($query->get());
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'address' => 'nullable|string|max:1000',
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
            'radius_meter' => 'nullable|integer|min:1',
            'work_start_time' => 'nullable|date_format:H:i',
            'work_end_time' => 'nullable|date_format:H:i|after:work_start_time',
        ]);

        $data['tenant_id'] = $this->tenantId($request);

        $location = Location::create($data);

        return response()->json($location, 201);
    }

    public function show(Location $location)
    {
        $this->ensureVisible($location);
        return response()->json($location);
    }

    public function update(Request $request, Location $location)
    {
        $this->ensureVisible($location);
        $data = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'address' => 'sometimes|nullable|string|max:1000',
            'latitude' => 'sometimes|required|numeric|between:-90,90',
            'longitude' => 'sometimes|required|numeric|between:-180,180',
            'radius_meter' => 'sometimes|nullable|integer|min:1',
            'work_start_time' => 'sometimes|date_format:H:i',
            'work_end_time' => 'sometimes|date_format:H:i|after:work_start_time',
        ]);

        $location->update($data);

        return response()->json($location);
    }

    public function destroy(Location $location)
    {
        $this->ensureVisible($location);
        $location->delete();

        return response()->json(['message' => 'Lokasi berhasil dihapus.']);
    }

    public function publicIndex()
    {
        $locations = \App\Models\Location::select('id', 'name')
            ->orderBy('name')
            ->get();

        return response()->json($locations);
    }

    private function tenantId(Request $request): int
    {
        $user = $request->user();
        if ($this->isSuperAdmin() && $request->filled('tenant_id')) {
            return (int) $request->integer('tenant_id');
        }

        return (int) ($user?->tenant_id ?? 1);
    }

    private function isSuperAdmin(): bool
    {
        return in_array(Auth::user()?->role, ['super_admin', 'superadmin'], true);
    }

    private function ensureVisible(Location $location): void
    {
        if (!$this->isSuperAdmin()) {
            abort_unless((int) $location->tenant_id === (int) (Auth::user()?->tenant_id ?? 1), 404);
        }
    }
}
