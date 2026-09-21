<?php

namespace App\Models;

use App\Models\Traits\HasTenant;
use Illuminate\Database\Eloquent\Model;

class Shift extends Model
{
    use HasTenant;

    protected $fillable = [
        'tenant_id',
        'division_id',
        'name',
        'work_start_time',
        'work_end_time',
        'is_active',
    ];

    protected $casts = ['is_active' => 'boolean'];

    public function division()
    {
        return $this->belongsTo(Division::class);
    }

    public function employees()
    {
        return $this->hasMany(User::class);
    }
}