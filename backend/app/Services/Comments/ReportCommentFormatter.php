<?php

namespace App\Services\Comments;

use App\Models\ReportComment;

class ReportCommentFormatter
{
    /**
     * @return array<string, mixed>
     */
    public function formatComment(ReportComment $comment): array
    {
        return [
            'id' => $comment->id,
            'commentable_type' => $comment->commentable_type,
            'commentable_id' => $comment->commentable_id,
            'user_id' => $comment->user_id,
            'author_username' => $comment->author_name,
            'author_avatar_url' => $comment->author_avatar_url,
            'is_anonymous' => $comment->is_anonymous,
            'comment_text' => $comment->comment_text,
            'created_at' => optional($comment->commented_at ?? $comment->created_at)?->toIso8601String(),
            'last_modified_at' => optional($comment->last_modified_at)?->toIso8601String(),
        ];
    }
}
