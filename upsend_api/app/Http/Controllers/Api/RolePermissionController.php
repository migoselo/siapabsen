<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Support\AdminPermissionCatalog;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class RolePermissionController extends Controller
{
    public function catalog(Request $request)
    {
        $this->ensureSuperAdmin($request);

        return response()->json(collect(AdminPermissionCatalog::all())
            ->map(fn ($permission) => [
                'id' => $permission['id'],
                'label' => $permission['label'],
                'description' => $permission['description'],
                'checked' => $permission['id'] === 'dashboard.view',
            ])
            ->values());
    }

    public function index(Request $request, User $user)
    {
        $this->ensureSuperAdmin($request);
        $this->ensureAdminTarget($user);

        $enabled = $user->permissions ?? AdminPermissionCatalog::ids();
        $permissions = collect(AdminPermissionCatalog::all())
            ->map(fn ($item) => [
                'id' => $item['id'],
                'label' => $item['label'],
                'description' => $item['description'],
                'checked' => in_array($item['id'], $enabled, true)
                    || collect($item['grants'])->every(fn ($grant) => in_array($grant, $enabled, true)),
            ])
            ->values();

        return response()->json([
            'user' => ['id' => $user->id, 'name' => $user->name, 'role' => $user->role],
            'permissions' => $permissions,
        ]);
    }

    public function update(Request $request, User $user)
    {
        $this->ensureSuperAdmin($request);
        $this->ensureAdminTarget($user);

        $data = $request->validate([
            'permissions' => ['required', 'array'],
            'permissions.*' => ['required', 'string', Rule::in(AdminPermissionCatalog::ids())],
        ]);

        $permissions = array_values(array_unique($data['permissions']));
        if (! in_array('dashboard.view', $permissions, true)) $permissions[] = 'dashboard.view';
        $user->permissions = $permissions;
        $user->save();

        return response()->json(['message' => 'Hak akses admin berhasil diperbarui.', 'permissions' => $user->permissions]);
    }

    private function ensureSuperAdmin(Request $request): void
    {
        abort_unless(in_array($request->user()?->role, ['super_admin', 'superadmin'], true), 403);
    }

    private function ensureAdminTarget(User $user): void
    {
        abort_unless($user->role === 'admin', 404, 'Hak akses hanya dapat diatur untuk akun admin perusahaan.');
    }
}
