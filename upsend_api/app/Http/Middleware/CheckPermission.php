<?php

namespace App\Http\Middleware;

use App\Support\AdminPermissionCatalog;
use Closure;
use Illuminate\Http\Request;

class CheckPermission
{
    public function handle(Request $request, Closure $next, string $permissions)
    {
        $user = $request->user();
        if (! $user) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }

        if (in_array($user->role, ['super_admin', 'superadmin'], true) || $user->role !== 'admin') {
            return $next($request);
        }

        if ($user->permissions === null) {
            return $next($request);
        }

        $granted = $user->permissions;
        foreach ($user->permissions as $permission) {
            $granted = array_merge($granted, AdminPermissionCatalog::implied()[$permission] ?? []);
        }

        foreach (explode('|', $permissions) as $permission) {
            if (in_array($permission, $granted, true)) {
                return $next($request);
            }
        }

        return response()->json(['message' => 'Akun admin tidak memiliki hak akses untuk fitur ini.'], 403);
    }
}