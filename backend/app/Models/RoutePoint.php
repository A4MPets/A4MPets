<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class RoutePoint extends Model
{
    protected $fillable = [
        'route_id',
        'sequence',
        'latitude',
        'longitude',
    ];

    protected $casts = [
        'sequence' => 'integer',
        'latitude' => 'float',
        'longitude' => 'float',
    ];

    public function route(): BelongsTo
    {
        return $this->belongsTo(TravelRoute::class, 'route_id');
    }
}
