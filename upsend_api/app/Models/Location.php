<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Location extends Model
{
    protected $fillable = ['name', 'latitude', 'longitude', 'radius_meter'];

    public function employees()
    {
        return $this->hasMany(User::class, 'home_location_id');
    }

    public function attendances()
    {
        return $this->hasMany(Attendance::class);
    }
}
