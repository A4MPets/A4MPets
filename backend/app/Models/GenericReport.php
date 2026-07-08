<?php

namespace App\Models;

use App\Models\Concerns\HasReportCommentsJson;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class GenericReport extends Model
{
    use HasReportCommentsJson;

    protected $fillable = [
        'user_id',
        'local_id',
        'remote_id',
        'latitude',
        'longitude',
        'description',
        'reported_date',
        'risk_level_code',
        'impact_radius_meters',
        'photo_url',
        'sync_status',
        'last_modified_at',
        'synced_at',
    ];

    protected $casts = [
        'latitude' => 'float',
        'longitude' => 'float',
        'impact_radius_meters' => 'integer',
        'reported_date' => 'datetime',
        'last_modified_at' => 'datetime',
        'synced_at' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    protected $appends = ['comments_json', 'reported_by_username'];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function getReportedByUsernameAttribute(): string
    {
        $user = $this->relationLoaded('user') ? $this->user : $this->user()->first();

        return $user?->name ?? 'Anonimo';
    }
}
