<?php

namespace App\Services\Hazards;

use App\Models\HazardReport;
use App\Models\ReportComment;

class HazardResponseFormatter
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
        ];
    }

    /**
     * @return array<string, mixed>
     */
    public function formatHazard(HazardReport $hazard): array
    {
        return [
            'id' => $hazard->id,
            'incident_latitude' => $hazard->incident_latitude,
            'incident_longitude' => $hazard->incident_longitude,
            'impact_radius_meters' => $hazard->impact_radius_meters,
            'risk_level_code' => $hazard->risk_level_code,
            'category_code' => $hazard->category_code,
            'estimated_duration_code' => $hazard->estimated_duration_code,
            'description' => $hazard->description,
            'narrative_description' => $hazard->narrative_description,
            'reported_at' => optional($hazard->reported_at)?->toIso8601String(),
            'evidence_photo_url' => $hazard->evidence_photo_url,
            'reported_by_username' => $hazard->reported_by_username,
            'user_id' => $hazard->user_id,
            'status' => $hazard->status,
            'comments_json' => $hazard->comments_json,
        ];
    }
}
