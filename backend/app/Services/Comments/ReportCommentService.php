<?php

namespace App\Services\Comments;

use App\Models\ReportComment;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Database\Eloquent\Model;

class ReportCommentService
{
    /**
     * @param  array<int, mixed>  $commentsData
     */
    public function syncComments(Model $commentable, array $commentsData): void
    {
        if ($commentsData === []) {
            return;
        }

        foreach ($commentsData as $commentData) {
            if (! is_array($commentData)) {
                continue;
            }

            $commentText = trim((string) ($commentData['comment_text'] ?? ''));
            if ($commentText === '') {
                continue;
            }

            $authorName = trim((string) ($commentData['author_username'] ?? $commentData['author_name'] ?? ''));
            $commentedAtValue = $this->parseCommentTimestamp(
                $commentData['created_at'] ?? $commentData['commented_at'] ?? null
            );
            $isAnonymous = (bool) ($commentData['is_anonymous'] ?? ($authorName === '' || $authorName === 'Anonimo'));

            $payload = [
                'commentable_type' => $commentable->getMorphClass(),
                'commentable_id' => $commentable->getKey(),
                'user_id' => $commentData['user_id'] ?? null,
                'author_name' => $authorName !== '' ? $authorName : 'Anonimo',
                'author_avatar_url' => $commentData['author_avatar_url'] ?? null,
                'is_anonymous' => $isAnonymous,
                'comment_text' => $commentText,
                'commented_at' => $commentedAtValue,
            ];
            $payload['content_hash'] = ReportComment::makeContentHash($payload);

            $existingByHash = ReportComment::query()
                ->where('commentable_type', $payload['commentable_type'])
                ->where('commentable_id', $payload['commentable_id'])
                ->where('content_hash', $payload['content_hash'])
                ->first();

            if ($existingByHash) {
                $existingByHash->update($payload);

                continue;
            }

            $equivalent = $this->findEquivalentComment($payload);
            if ($equivalent) {
                $payload['content_hash'] = $equivalent->content_hash;
                $equivalent->update($payload);

                continue;
            }

            ReportComment::create($payload);
        }

        $this->pruneDuplicateComments($commentable);
    }

    /**
     * @param  array<string, mixed>  $validated
     */
    public function storeComment(Model $commentable, ?User $user, array $validated): ReportComment
    {
        $isAnonymous = (bool) ($validated['is_anonymous'] ?? false);
        $authorName = trim((string) ($validated['author_name'] ?? ''));

        if ($authorName === '') {
            $authorName = $user && ! $isAnonymous ? $user->name : 'Anonimo';
        }

        $commentedAt = $this->parseCommentTimestamp($validated['created_at'] ?? null);
        $payload = [
            'commentable_type' => $commentable->getMorphClass(),
            'commentable_id' => $commentable->getKey(),
            'user_id' => $user && ! $isAnonymous ? $user->id : null,
            'author_name' => $authorName,
            'author_avatar_url' => $validated['author_avatar_url'] ?? null,
            'is_anonymous' => $isAnonymous || $user === null,
            'comment_text' => $validated['comment_text'],
            'commented_at' => $commentedAt,
        ];
        $payload['content_hash'] = ReportComment::makeContentHash($payload);

        $comment = ReportComment::updateOrCreate(
            [
                'commentable_type' => $payload['commentable_type'],
                'commentable_id' => $payload['commentable_id'],
                'content_hash' => $payload['content_hash'],
            ],
            $payload
        );

        return $comment;
    }

    private function parseCommentTimestamp(mixed $value): Carbon
    {
        if ($value instanceof Carbon) {
            return $value;
        }

        if (is_int($value) || is_float($value) || (is_string($value) && ctype_digit($value))) {
            return Carbon::createFromTimestampMs((int) $value);
        }

        if (is_string($value) && trim($value) !== '') {
            return Carbon::parse($value);
        }

        return now();
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    private function findEquivalentComment(array $payload): ?ReportComment
    {
        $query = ReportComment::query()
            ->where('commentable_type', (string) ($payload['commentable_type'] ?? ''))
            ->where('commentable_id', (int) ($payload['commentable_id'] ?? 0))
            ->where('author_name', (string) ($payload['author_name'] ?? ''))
            ->where('is_anonymous', (bool) ($payload['is_anonymous'] ?? false))
            ->where('comment_text', (string) ($payload['comment_text'] ?? ''));

        if (array_key_exists('user_id', $payload) && $payload['user_id'] !== null) {
            $query->where('user_id', (int) $payload['user_id']);
        } else {
            $query->whereNull('user_id');
        }

        $commentedAt = $payload['commented_at'] ?? null;
        if ($commentedAt instanceof Carbon) {
            $start = $commentedAt->copy()->startOfSecond();
            $end = $start->copy()->addSecond();
            $query->whereBetween('commented_at', [$start, $end]);
        }

        return $query->orderBy('id')->first();
    }

    private function pruneDuplicateComments(Model $commentable): void
    {
        $seen = [];
        $comments = ReportComment::query()
            ->where('commentable_type', $commentable->getMorphClass())
            ->where('commentable_id', $commentable->getKey())
            ->orderBy('id')
            ->get();

        foreach ($comments as $comment) {
            $key = implode('|', [
                $commentable->getMorphClass(),
                $commentable->getKey(),
                $comment->user_id ?? 'null',
                $comment->author_name,
                (int) $comment->is_anonymous,
                $comment->comment_text,
                optional($comment->commented_at)->format('Y-m-d H:i:s') ?? '',
            ]);

            if (isset($seen[$key])) {
                $comment->delete();

                continue;
            }

            $seen[$key] = true;
        }
    }
}
