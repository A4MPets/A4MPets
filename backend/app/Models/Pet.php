<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Pet extends Model
{
    protected $table = 'pets';

    protected $fillable = [
        'user_id',
        'local_id',
        'local_uuid',
        'remote_id',
        'name',
        'photo_path',
        'total_walks',
        'registered_at',
        'adoption_date',
        'birth_date',
        'status',
        'is_ownerless',
        'sync_status',
        'last_modified_at',
        'synced_at',
    ];

    protected $casts = [
        'total_walks' => 'integer',
        'registered_at' => 'datetime',
        'adoption_date' => 'datetime',
        'birth_date' => 'datetime',
        'is_ownerless' => 'boolean',
        'last_modified_at' => 'datetime',
        'synced_at' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function lostPetReports(): HasMany
    {
        return $this->hasMany(LostPetReport::class);
    }

    public function foundPetReports(): HasMany
    {
        return $this->hasMany(FoundPetReport::class);
    }
}
