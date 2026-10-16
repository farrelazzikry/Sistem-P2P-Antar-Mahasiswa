<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Tebengan extends Model
{
    use HasFactory;

    protected $fillable = [
        'requester_id',
        'runner_id',
        'pickup_location',
        'destination',
        'departure_time',
        'budget',
        'fee',
        'whatsapp_number',
        'status',
    ];

    protected $casts = [
        'budget' => 'float',
        'fee' => 'float',
        'departure_time' => 'datetime',
    ];

    protected $appends = [
        'requester_has_rated',
        'runner_has_rated',
    ];

    public function requester()
    {
        return $this->belongsTo(User::class, 'requester_id');
    }

    public function runner()
    {
        return $this->belongsTo(User::class, 'runner_id');
    }

    public function ratings()
    {
        return $this->morphMany(Rating::class, 'rateable');
    }

    public function getRequesterHasRatedAttribute()
    {
        if (!$this->requester_id) return false;
        return Rating::where('rateable_type', 'App\Models\Tebengan')
            ->where('rateable_id', $this->id)
            ->where('rater_id', $this->requester_id)
            ->exists();
    }

    public function getRunnerHasRatedAttribute()
    {
        if (!$this->runner_id) return false;
        return Rating::where('rateable_type', 'App\Models\Tebengan')
            ->where('rateable_id', $this->id)
            ->where('rater_id', $this->runner_id)
            ->exists();
    }
}