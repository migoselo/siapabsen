<?php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use App\Models\Traits\HasTenant; // pastikan trait ini ada di app/Models/Traits/HasTenant.php
use App\Models\Location;
use App\Models\Attendance;

class User extends Authenticatable
{
    use HasApiTokens, Notifiable, HasTenant;

    protected $fillable = [
        'name', 'email', 'password', 'no_hp', 'role', 'home_location_id', 'is_active',
        // tenant_id ditambahkan supaya bisa di-set oleh migration/bootHasTenant
        'tenant_id',
    ];

    protected $hidden = ['password', 'remember_token'];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function homeLocation()
    {
        return $this->belongsTo(Location::class, 'home_location_id');
    }

    public function attendances()
    {
        return $this->hasMany(Attendance::class, 'employee_id');
    }

    public function leaveRequests()
    {
        return $this->hasMany(LeaveRequest::class);
    }

    public function tenant()
    {
        return $this->belongsTo(\App\Models\Tenant::class);
    }

    public function isAdmin(): bool
    {
        return $this->role === 'admin';
    }
}