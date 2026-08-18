<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UserFace extends Model
{
    use HasFactory;

    protected $table = 'user_faces';

    protected $fillable = [
        'user_id',
        'image_path',
        'embedding',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
