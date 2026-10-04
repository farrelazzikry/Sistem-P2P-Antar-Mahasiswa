<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'username',       
        'email',
        'password',
        'nim',            
        'ktm_path',       
        'otp_code',       
        'otp_expires_at', 
        'status',
        'admin_note',
        'phone',
        'profile_photo',
        'is_runner',
        'vehicle_type',
        'vehicle_plate',
        'rating_as_driver',
        'rating_as_requester',
        'total_trips',
    ];

    protected $hidden = [
        'password',
        'remember_token',
        'otp_code',       // Sembunyiin biar gak keliatan di response API
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'otp_expires_at' => 'datetime',
            'password' => 'hashed',
        ];
    }
}