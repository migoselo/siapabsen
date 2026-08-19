<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LeaveRequestLog extends Model
{
    public $timestamps = false; // cuma ada created_at, ga ada updated_at
    protected $fillable = ['leave_request_id', 'status', 'note', 'tenant_id'];
}