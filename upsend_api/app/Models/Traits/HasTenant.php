<?php

namespace App\Models\Traits;

use Illuminate\Support\Facades\Auth;

/**
 * @mixin \Illuminate\Database\Eloquent\Model
 * @method static void creating(callable $callback)
 * @method static void created(callable $callback)
 */
trait HasTenant
{
    /**
     * Scope to filter by tenant. If tenantId null, uses app('currentTenant') if available.
     * Usage: Model::forTenant()->get();
     */
    public function scopeForTenant($query, $tenantId = null)
    {
        $tenant = app()->bound('currentTenant') ? app('currentTenant') : null;
        $tenantId = $tenantId ?? (optional($tenant)->id ?? $tenant ?? null);

        if ($tenantId) {
            return $query->where('tenant_id', $tenantId);
        }

        return $query;
    }

    /**
     * Automatically fill tenant_id when a model is created.
     */
    protected static function bootHasTenant(): void
    {
        static::creating(function ($model) {
            if (! empty($model->tenant_id)) {
                return;
            }

            $tenantId = null;

            if (app()->bound('currentTenant')) {
                $tenant = app('currentTenant');
                $tenantId = $tenant instanceof \App\Models\Tenant ? $tenant->id : $tenant;
            }

            if (empty($tenantId) && Auth::check()) {
                $tenantId = Auth::user()->tenant_id ?? null;
            }

            if (empty($tenantId) && \App\Models\Tenant::query()->exists()) {
                $tenantId = \App\Models\Tenant::query()->value('id');
            }

            if (empty($tenantId)) {
                $tenantId = 1;
            }

            $model->tenant_id = (int) $tenantId;
        });
    }
}