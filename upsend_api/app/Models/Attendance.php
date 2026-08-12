<?php

namespace App\Models;

use App\Models\Traits\HasTenant;
use Illuminate\Database\Eloquent\Model;

class Attendance extends Model
{
    use HasTenant;

    protected $fillable = [
        'employee_id', 'user_id', 'location_id', 'tenant_id',
        'check_in_time', 'check_in_lat', 'check_in_long', 'check_in_distance', 'check_in_photo',
        'check_out_time', 'check_out_lat', 'check_out_long', 'check_out_distance', 'check_out_photo',
        'status',
    ];

    protected $casts = [
        'check_in_time' => 'datetime',
        'check_out_time' => 'datetime',
    ];

    public function employee()
    {
        return $this->belongsTo(User::class, 'employee_id');
    }

    public function location()
    {
        return $this->belongsTo(Location::class);
    }

    public function tenant()
    {
        return $this->belongsTo(\App\Models\Tenant::class);
    }
}
