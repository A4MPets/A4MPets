<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphMany;

class GenericReport extends Model
{
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

    protected $appends = ['comments_json'];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function comments(): MorphMany
    {
        return $this->morphMany(ReportComment::class, 'commentable')->orderBy('commented_at')->orderBy('id');
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
