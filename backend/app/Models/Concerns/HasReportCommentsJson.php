<?php

namespace App\Models\Concerns;

use App\Models\ReportComment;
use Illuminate\Database\Eloquent\Relations\MorphMany;

trait HasReportCommentsJson
{
    public function comments(): MorphMany
    {
        return $this->morphMany(ReportComment::class, 'commentable')->orderBy('commented_at')->orderBy('id');
    }

    public function getCommentsJsonAttribute(): string
    {
        $comments = $this->relationLoaded('comments') ? $this->comments : $this->comments()->get();

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
