<?php

namespace App\Models\Traits;

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
        $tenantId = $tenantId ?? (optional(app('currentTenant'))->id ?? app('currentTenant') ?? null);

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
            if (empty($model->tenant_id)) {
                $tenantId = optional(app('currentTenant'))->id ?? app('currentTenant') ?? null;

                if ($tenantId) {
                    $model->tenant_id = $tenantId;
                }
            }
        });
    }
}