<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use App\Models\Tenant;

class SetTenant
{
    /**
     * Handle an incoming request.
     * Reads tenant id from header X-Tenant-ID, or request input tenant_id.
     * Sets app('currentTenant') to Tenant model instance (or null).
     */
    public function handle(Request $request, Closure $next)
    {
        // Bind a default null value so app('currentTenant') is always safe.
        if (! app()->bound('currentTenant')) {
            app()->instance('currentTenant', null);
        }
        $request->attributes->set('currentTenant', null);

        $tenantId = $request->header('X-Tenant-ID') ?? $request->input('tenant_id');

        if ($tenantId) {
            // Try load Tenant model if exists
            try {
                $tenant = \App\Models\Tenant::find($tenantId);
            } catch (\Throwable $e) {
                $tenant = null;
            }

            if ($tenant) {
                app()->instance('currentTenant', $tenant);
                // attach juga ke request attributes untuk controller akses mudah
                $request->attributes->set('currentTenant', $tenant);
            } else {
                // Jika tidak ada model Tenant, simpan id mentah agar bisa digunakan
                app()->instance('currentTenant', (int)$tenantId);
                $request->attributes->set('currentTenant', (int)$tenantId);
            }
        }

        return $next($request);
    }
}