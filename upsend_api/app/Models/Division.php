<?php

namespace App\Models;

use App\Models\Traits\HasTenant;
use Illuminate\Database\Eloquent\Model;

class Division extends Model
{
    use HasTenant;

    protected $fillable = ['tenant_id', 'name', 'description', 'is_active'];

    protected $casts = ['is_active' => 'boolean'];

    public function shifts()
    {
        return $this->hasMany(Shift::class);
    }

    public function employees()
    {
        return $this->hasMany(User::class);
    }
}