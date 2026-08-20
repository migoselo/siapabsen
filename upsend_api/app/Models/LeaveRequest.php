<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class LeaveRequest extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'leave_type_id',
        'type',
        'start_date',
        'end_date',
        'reason',
        'attachment_path',
        'status',
        'total_days',
        'start_time',
        'end_time',
    ];

    protected $casts = [
        'start_date' => 'date',
        'end_date' => 'date',
    ];

    protected $appends = ['attachment_url', 'attachment_name'];

    public function getAttachmentUrlAttribute(): ?string
    {
        if (!$this->attachment_path) return null;

        return '/storage/' . ltrim($this->attachment_path, '/');
    }

    public function getAttachmentNameAttribute(): ?string
    {
        if (!$this->attachment_path) return null;

        return basename($this->attachment_path);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
