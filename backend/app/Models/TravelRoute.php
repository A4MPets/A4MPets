<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TravelRoute extends Model
{
    protected $table = 'routes';

    protected $fillable = [
        'user_id',
        'local_id',
        'remote_id',
        'name',
        'points_json',
        'sync_status',
        'last_modified_at',
        'synced_at',
    ];

    protected $casts = [
        'last_modified_at' => 'datetime',
        'synced_at' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
