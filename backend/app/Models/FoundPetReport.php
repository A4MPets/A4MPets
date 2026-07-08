<?php

namespace App\Models;

use App\Models\Concerns\HasPetPhotoUrl;
use App\Models\Concerns\HasReportCommentsJson;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FoundPetReport extends Model
{
    use HasPetPhotoUrl;
    use HasReportCommentsJson;

    protected $fillable = [
        'user_id',
        'pet_id',
        'matched_lost_pet_report_id',
        'pet_local_uuid',
        'local_id',
        'remote_id',
        'latitude',
        'longitude',
        'details',
        'found_date',
        'photo_url',
        'phone',
        'sync_status',
        'last_modified_at',
        'synced_at',
    ];

    protected $casts = [
        'latitude' => 'float',
        'longitude' => 'float',
        'found_date' => 'datetime',
        'last_modified_at' => 'datetime',
        'synced_at' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    protected $appends = ['comments_json', 'pet_photo_url'];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function pet(): BelongsTo
    {
        return $this->belongsTo(Pet::class);
    }

    public function matchedLostPetReport(): BelongsTo
    {
        return $this->belongsTo(LostPetReport::class, 'matched_lost_pet_report_id');
    }
}
