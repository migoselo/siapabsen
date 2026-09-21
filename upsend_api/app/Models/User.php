<?php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use App\Models\Traits\HasTenant; // pastikan trait ini ada di app/Models/Traits/HasTenant.php
use App\Models\Location;
use App\Models\Attendance;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable, HasTenant;

    protected $fillable = [
        'name', 'email', 'password', 'no_hp', 'role', 'home_location_id', 'is_active',
        'employee_id',
        'division_id', 'shift_id',
        'department', 'grade', 'employee_type', 'joined_at', 'nik', 'birth_place',
        'birth_date', 'gender', 'religion', 'blood_type', 'marital_status', 'address',
        'emergency_contact', 'bank_name', 'bank_account_number', 'bank_account_name',
        'tax_number', 'bpjs_employment', 'bpjs_health', 'last_education',
        'education_institution', 'certification', 'spouse_name', 'father_name',
        'mother_name', 'children_count',
        // tenant_id ditambahkan supaya bisa di-set oleh migration/bootHasTenant
        'tenant_id',
    ];

    protected $hidden = ['password', 'remember_token'];

    protected $casts = [
        'is_active' => 'boolean',
        'joined_at' => 'date:Y-m-d',
        'birth_date' => 'date:Y-m-d',
        'children_count' => 'integer',
    ];

    public function homeLocation()
    {
        return $this->belongsTo(Location::class, 'home_location_id');
    }

    public function division()
    {
        return $this->belongsTo(Division::class);
    }

    public function shift()
    {
        return $this->belongsTo(Shift::class);
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