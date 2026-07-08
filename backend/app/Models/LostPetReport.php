<?php

namespace App\Models;

use App\Models\Concerns\HasPetPhotoUrl;
use App\Models\Concerns\HasReportCommentsJson;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class LostPetReport extends Model
{
    use HasFactory;
    use HasPetPhotoUrl;
    use HasReportCommentsJson;

    protected $fillable = [
        'user_id',
        'pet_id',
        'pet_local_uuid',
        'local_id',
        'remote_id',
        'last_seen_latitude',
        'last_seen_longitude',
        'name',
        'details',
        'disappearance_date',
        'photo_url',
        'phone',
        'sync_status',
        'last_modified_at',
        'synced_at',
    ];

    protected $casts = [
        'last_seen_latitude' => 'float',
        'last_seen_longitude' => 'float',
        'disappearance_date' => 'datetime',
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
}
