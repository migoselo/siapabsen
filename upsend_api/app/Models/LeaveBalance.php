<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LeaveBalance extends Model
{
    protected $fillable = ['user_id', 'leave_type_id', 'year', 'quota_days', 'used_days', 'tenant_id'];

    public function leaveType()
    {
        return $this->belongsTo(LeaveType::class);
    }
}