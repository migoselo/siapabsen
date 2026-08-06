<?php

namespace App\Models;

use App\Models\Traits\HasTenant;
use Illuminate\Database\Eloquent\Model;

class Location extends Model
{
    use HasTenant;

    protected $fillable = ['name', 'latitude', 'longitude', 'radius_meter', 'tenant_id'];

    public function employees()
    {
        return $this->hasMany(User::class, 'home_location_id');
    }

    public function attendances()
    {
        return $this->hasMany(Attendance::class);
    }

    public function tenant()
    {
        return $this->belongsTo(\App\Models\Tenant::class);
    }
}
