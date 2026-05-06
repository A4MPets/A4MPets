<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphMany;

class LostPetReport extends Model
{
    use HasFactory;
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

    public function comments(): MorphMany
    {
        return $this->morphMany(ReportComment::class, 'commentable')->orderBy('commented_at')->orderBy('id');
    }

    public function getPetPhotoUrlAttribute(): ?string
    {
        $pet = $this->relationLoaded('pet') ? $this->pet : $this->pet()->first();

        return $this->photo_url ?? $pet?->photo_path;
    }

    public function getCommentsJsonAttribute(): string
    {
        $comments = $this->relationLoaded('comments')
            ? $this->comments
            : $this->comments()->get();

        return $comments->values()->map(static function (ReportComment $comment): array {
            $commentedAt = $comment->commented_at ?? $comment->created_at ?? now();
            $timestampMs = ($commentedAt->getTimestamp() * 1000)
                + (int) floor(((int) $commentedAt->format('u')) / 1000);

            return [
                'author_username' => $comment->author_name,
                'author_avatar_url' => $comment->author_avatar_url,
                'is_anonymous' => $comment->is_anonymous,
                'comment_text' => $comment->comment_text,
                'created_at' => $timestampMs,
            ];
        })->toJson();
    }
}
