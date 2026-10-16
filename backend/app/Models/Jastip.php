<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Jastip extends Model
{
    use HasFactory;

    protected $fillable = [
        'requester_id',
        'runner_id',
        'item_name',
        'item_description',
        'buy_location',
        'delivery_location',
        'budget',
        'fee',
        'whatsapp_number',
        'status',
        'proof_photo',
    ];

    protected $casts = [
        'budget' => 'float',
        'fee' => 'float',
    ];

    // Relasi ke User (pemesan)
    public function requester()
    {
        return $this->belongsTo(User::class, 'requester_id');
    }

    // Relasi ke User (runner)
    public function runner()
    {
        return $this->belongsTo(User::class, 'runner_id');
    }
        protected $appends = [
        'requester_has_rated',
        'runner_has_rated',
    ];

    // Relasi ke Rating
    public function ratings()
    {
        return $this->morphMany(Rating::class, 'rateable');
    }

    public function getRequesterHasRatedAttribute()
    {
        if (!$this->requester_id) return false;
        return Rating::where('rateable_type', 'App\Models\Jastip')
            ->where('rateable_id', $this->id)
            ->where('rater_id', $this->requester_id)
            ->exists();
    }

    public function getRunnerHasRatedAttribute()
    {
        if (!$this->runner_id) return false;
        return Rating::where('rateable_type', 'App\Models\Jastip')
            ->where('rateable_id', $this->id)
            ->where('rater_id', $this->runner_id)
            ->exists();
    }
}