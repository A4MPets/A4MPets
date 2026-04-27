<?php

namespace App\Services\Hazards;

use App\Models\HazardComment;
use App\Models\HazardReport;
use App\Models\User;
use Carbon\Carbon;

class HazardCommentSyncService
{
    /**
     * @param  array<int, mixed>  $commentsData
     */
    public function syncComments(HazardReport $hazardReport, array $commentsData): void
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
            $commentedAt = $commentData['created_at'] ?? $commentData['commented_at'] ?? null;
            $commentedAtValue = $this->parseCommentTimestamp($commentedAt);
            $isAnonymous = (bool) ($commentData['is_anonymous'] ?? ($authorName === '' || $authorName === 'Anonimo'));

            $payload = [
                'hazard_report_id' => $hazardReport->id,
                'user_id' => $commentData['user_id'] ?? null,
                'author_name' => $authorName !== '' ? $authorName : 'Anonimo',
                'author_avatar_url' => $commentData['author_avatar_url'] ?? null,
                'is_anonymous' => $isAnonymous,
                'comment_text' => $commentText,
                'commented_at' => $commentedAtValue,
                'last_modified_at' => now(),
                'synced_at' => now(),
            ];
            $payload['content_hash'] = HazardComment::makeContentHash($payload);

            $existingByHash = HazardComment::query()
                ->where('hazard_report_id', $hazardReport->id)
                ->where('content_hash', $payload['content_hash'])
                ->first();

            if ($existingByHash) {
                $existingByHash->update($payload);

                continue;
            }

            $equivalent = $this->findEquivalentComment($hazardReport->id, $payload);
            if ($equivalent) {
                $payload['content_hash'] = $equivalent->content_hash;
                $equivalent->update($payload);

                continue;
            }

            HazardComment::create($payload);
        }

        $this->pruneDuplicateComments($hazardReport->id);

        $hazardReport->update([
            'last_modified_at' => now(),
        ]);
    }

    /**
     * @param  array<string, mixed>  $validated
     */
    public function storeComment(HazardReport $hazardReport, ?User $user, array $validated): HazardComment
    {
        $isAnonymous = (bool) ($validated['is_anonymous'] ?? false);
        $authorName = trim((string) ($validated['author_name'] ?? ''));

        if ($authorName === '') {
            $authorName = $user && ! $isAnonymous ? $user->name : 'Anonimo';
        }

        $commentedAt = $this->parseCommentTimestamp($validated['created_at'] ?? null);

        $payload = [
            'hazard_report_id' => $hazardReport->id,
            'user_id' => $user && ! $isAnonymous ? $user->id : null,
            'author_name' => $authorName,
            'author_avatar_url' => $validated['author_avatar_url'] ?? null,
            'is_anonymous' => $isAnonymous || $user === null,
            'comment_text' => $validated['comment_text'],
            'commented_at' => $commentedAt,
            'last_modified_at' => $commentedAt,
            'synced_at' => now(),
        ];
        $payload['content_hash'] = HazardComment::makeContentHash($payload);

        $comment = HazardComment::updateOrCreate(
            [
                'hazard_report_id' => $hazardReport->id,
                'content_hash' => $payload['content_hash'],
            ],
            $payload
        );

        $hazardReport->update([
            'last_modified_at' => now(),
        ]);

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
    private function findEquivalentComment(int $hazardId, array $payload): ?HazardComment
    {
        $query = HazardComment::query()
            ->where('hazard_report_id', $hazardId)
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

    private function pruneDuplicateComments(int $hazardId): void
    {
        $seen = [];
        $comments = HazardComment::query()
            ->where('hazard_report_id', $hazardId)
            ->orderBy('id')
            ->get();

        foreach ($comments as $comment) {
            $key = implode('|', [
                $hazardId,
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
