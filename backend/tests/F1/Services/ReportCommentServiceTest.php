<?php

namespace Tests\F1\Services;

use App\Services\Comments\ReportCommentService;
use App\Models\HazardReport;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Pruebas unitarias para ReportCommentService
 * Casos: F1-015, F1-016
 */
class ReportCommentServiceTest extends TestCase
{
    use RefreshDatabase;

    private ReportCommentService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = new ReportCommentService();
        // Hazard classifications are populated during migrations via RefreshDatabase
    }

    /**
     * F1-015: storeComment crea un comentario asociado a un reporte con todos los campos correctos
     */
    public function test_store_comment_creates_comment_with_all_fields(): void
    {
        $user = User::factory()->create(['name' => 'qa_user']);
        $hazard = HazardReport::create([
            'user_id'                 => $user->id,
            'incident_latitude'       => 4.711,
            'incident_longitude'      => -74.072,
            'impact_radius_meters'    => 100,
            'description'             => 'Hazard for comment test',
            'narrative_description'   => 'Hazard for comment test',
            'reported_by_username'    => 'qa_user',
            'risk_level_code'         => 'medium',
            'category_code'           => 'pest_presence',
            'estimated_duration_code' => '1_week',
            'status'                  => 'created',
            'reported_at'             => now(),
        ]);

        $validated = [
            'comment_text' => 'Comentario de prueba QA',
            'is_anonymous' => false,
        ];

        $comment = $this->service->storeComment($hazard, $user, $validated);

        $this->assertEquals('Comentario de prueba QA', $comment->comment_text);
        $this->assertEquals($user->id, $comment->user_id);
        $this->assertFalse((bool) $comment->is_anonymous);
        $this->assertEquals($user->name, $comment->author_name);
        $this->assertNotNull($comment->content_hash);
    }

    /**
     * F1-015-extra: storeComment para usuario anonimo no asocia user_id
     */
    public function test_store_comment_anonymous_does_not_link_user_id(): void
    {
        $hazard = HazardReport::create([
            'incident_latitude'       => 4.711,
            'incident_longitude'      => -74.072,
            'impact_radius_meters'    => 100,
            'description'             => 'Hazard for anon comment',
            'narrative_description'   => 'Hazard for anon comment',
            'reported_by_username'    => 'qa_anon',
            'risk_level_code'         => 'low',
            'category_code'           => 'pest_presence',
            'estimated_duration_code' => '1_day',
            'status'                  => 'created',
            'reported_at'             => now(),
        ]);

        $validated = [
            'comment_text' => 'Comentario anonimo',
            'is_anonymous' => true,
        ];

        $comment = $this->service->storeComment($hazard, null, $validated);

        $this->assertNull($comment->user_id);
        $this->assertTrue((bool) $comment->is_anonymous);
        $this->assertEquals('Anonimo', $comment->author_name);
    }

    /**
     * F1-016-extra: storeComment evita duplicados usando content_hash
     */
    public function test_store_comment_deduplicates_via_content_hash(): void
    {
        $user   = User::factory()->create();
        $hazard = HazardReport::create([
            'incident_latitude'       => 4.711,
            'incident_longitude'      => -74.072,
            'impact_radius_meters'    => 100,
            'description'             => 'Hazard for dedup test',
            'narrative_description'   => 'Hazard for dedup test',
            'reported_by_username'    => 'qa_dedup',
            'risk_level_code'         => 'high',
            'category_code'           => 'stagnant_water',
            'estimated_duration_code' => '3_days',
            'status'                  => 'created',
            'reported_at'             => now(),
        ]);

        $validated = ['comment_text' => 'Comentario duplicado', 'is_anonymous' => false];

        $this->service->storeComment($hazard, $user, $validated);
        $this->service->storeComment($hazard, $user, $validated);

        // Solo debe haber un comentario
        $this->assertEquals(1, $hazard->comments()->count());
    }
}
