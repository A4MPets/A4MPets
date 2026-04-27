<?php

namespace App\Models;

use Carbon\Carbon;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class HazardComment extends Model
{
    protected $fillable = [
        'hazard_report_id',
        'user_id',
        'author_name',
        'author_avatar_url',
        'is_anonymous',
        'comment_text',
        'commented_at',
        'content_hash',
        'last_modified_at',
        'synced_at',
    ];

    protected $casts = [
        'is_anonymous' => 'boolean',
        'commented_at' => 'datetime',
        'last_modified_at' => 'datetime',
        'synced_at' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    public function hazardReport(): BelongsTo
    {
        return $this->belongsTo(HazardReport::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public static function makeContentHash(array $attributes): string
    {
        $commentedAt = self::normalizeTimestampToSecond($attributes['commented_at'] ?? null);

        return hash('sha256', implode('|', [
            (string) ($attributes['hazard_report_id'] ?? ''),
            (string) ($attributes['user_id'] ?? ''),
            (string) ($attributes['author_name'] ?? ''),
            (string) ($attributes['author_avatar_url'] ?? ''),
            (string) ((int) ($attributes['is_anonymous'] ?? false)),
            (string) ($attributes['comment_text'] ?? ''),
            (string) $commentedAt,
        ]));
    }

    private static function normalizeTimestampToSecond(mixed $value): string
    {
        if ($value instanceof \DateTimeInterface) {
            return (string) $value->getTimestamp();
        }

        if (is_int($value) || is_float($value)) {
            return (string) intdiv((int) $value, 1000);
        }

        if (is_string($value) && ctype_digit($value)) {
            return (string) intdiv((int) $value, 1000);
        }

        if (is_string($value) && trim($value) !== '') {
            try {
                return (string) Carbon::parse($value)->getTimestamp();
            } catch (\Throwable) {
                return trim($value);
            }
        }

        return '';
    }
}
