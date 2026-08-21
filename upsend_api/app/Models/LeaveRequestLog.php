<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LeaveRequestLog extends Model
{
    public $timestamps = false;

    protected $fillable = [
        'leave_request_id',
        'status',
        'note',
        'tenant_id',
    ];

    public function leaveRequest()
    {
        return $this->belongsTo(LeaveRequest::class);
    }
}
