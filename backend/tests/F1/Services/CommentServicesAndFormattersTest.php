<?php

namespace Tests\F1\Services;

use App\Models\GenericReport;
use App\Models\HazardReport;
use App\Models\ReportComment;
use App\Models\User;
use App\Services\Comments\ReportCommentFormatter;
use App\Services\Comments\ReportCommentService;
use App\Services\Hazards\HazardCommentSyncService;
use App\Services\Hazards\HazardResponseFormatter;
use Carbon\Carbon;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * F1-016/F1-019-extra: Comment synchronization and response formatter coverage.
 */
class CommentServicesAndFormattersTest extends TestCase
{
    use RefreshDatabase;

    /**
     * F1-016: ReportCommentService syncs, filters, deduplicates and formats comments.
     */
    public function test_report_comment_service_syncs_filters_deduplicates_and_formats_comments(): void
    {
        $user = User::factory()->create(['name' => 'QA User']);
        $report = GenericReport::create([
            'user_id' => $user->id,
            'latitude' => 4.71,
            'longitude' => -74.07,
            'description' => 'Report',
            'reported_date' => now(),
            'risk_level_code' => 'low',
            'impact_radius_meters' => 10,
        ]);
        $service = new ReportCommentService();

        $service->syncComments($report, [
            'not-array',
            ['comment_text' => '   '],
            [
                'user_id' => $user->id,
                'author_username' => 'QA User',
                'comment_text' => 'Comentario sincronizado',
                'created_at' => 1778241600000,
                'is_anonymous' => false,
            ],
            [
                'user_id' => $user->id,
                'author_name' => 'QA User',
                'comment_text' => 'Comentario sincronizado',
                'commented_at' => Carbon::createFromTimestampMs(1778241600000),
                'is_anonymous' => false,
            ],
        ]);

        $this->assertSame(1, $report->comments()->count());

        $stored = $service->storeComment($report, $user, [
            'comment_text' => 'Comentario manual',
            'created_at' => '2026-05-08 10:00:00',
        ]);
        $anonymous = $service->storeComment($report, $user, [
            'comment_text' => 'Anonimo manual',
            'is_anonymous' => true,
        ]);

        $this->assertSame($user->id, $stored->user_id);
        $this->assertNull($anonymous->user_id);

        $formatted = (new ReportCommentFormatter())->formatComment($stored);
        $this->assertSame('QA User', $formatted['author_username']);
        $this->assertSame('Comentario manual', $formatted['comment_text']);
        $this->assertArrayHasKey('created_at', $formatted);
    }

    /**
     * F1-019-extra: HazardResponseFormatter formats hazard payloads with comments.
     */
    public function test_hazard_response_formatter_formats_hazard_and_comments(): void
    {
        $hazard = HazardReport::factory()->create([
            'risk_level_code' => 'high',
            'category_code' => 'pest_presence',
            'estimated_duration_code' => '1_day',
        ]);
        $comment = ReportComment::create([
            'commentable_type' => HazardReport::class,
            'commentable_id' => $hazard->id,
            'author_name' => 'QA',
            'is_anonymous' => true,
            'comment_text' => 'Comentario hazard',
            'commented_at' => '2026-05-08 10:00:00',
            'content_hash' => ReportComment::makeContentHash([
                'commentable_type' => HazardReport::class,
                'commentable_id' => $hazard->id,
                'author_name' => 'QA',
                'is_anonymous' => true,
                'comment_text' => 'Comentario hazard',
                'commented_at' => '2026-05-08 10:00:00',
            ]),
        ]);

        $formatter = new HazardResponseFormatter();
        $hazardPayload = $formatter->formatHazard($hazard->refresh());
        $commentPayload = $formatter->formatComment($comment);

        $this->assertSame($hazard->id, $hazardPayload['id']);
        $this->assertSame('high', $hazardPayload['risk_level_code']);
        $this->assertSame('Comentario hazard', $commentPayload['comment_text']);
    }

    /**
     * F1-016-extra: HazardCommentSyncService legacy paths are covered and documented.
     */
    public function test_legacy_hazard_comment_service_empty_sync_returns_and_store_documents_removed_column(): void
    {
        $hazard = HazardReport::factory()->create();
        $user = User::factory()->create();
        $service = new HazardCommentSyncService();

        $service->syncComments($hazard, []);
        $this->assertDatabaseCount('hazard_comments', 0);

        $this->expectException(QueryException::class);
        $service->storeComment($hazard, $user, [
            'comment_text' => 'Legacy comment',
            'created_at' => '2026-05-08 10:00:00',
        ]);
    }
}
