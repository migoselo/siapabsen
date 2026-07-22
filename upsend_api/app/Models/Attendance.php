<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Attendance extends Model
{
    protected $fillable = [
        'employee_id', 'location_id',
        'check_in_time', 'check_in_lat', 'check_in_lng', 'check_in_distance', 'check_in_photo',
        'check_out_time', 'check_out_lat', 'check_out_lng', 'check_out_distance',
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
}
