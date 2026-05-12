<?php

namespace Tests\F3\Hazards;

use App\Models\HazardReport;
use App\Models\ReportComment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\CreatesApiToken;
use Tests\TestCase;

/**
 * Pruebas de feature para CRUD de peligros ambientales
 * Casos: F3-016, F3-017
 */
class HazardCrudTest extends TestCase
{
    use RefreshDatabase, CreatesApiToken;

    // Hazard classifications are populated during migrations via RefreshDatabase

    /**
     * F3-016: Crear reporte de peligro con todos los campos obligatorios retorna HTTP 201
     */
    public function test_create_hazard_report_returns_201(): void
    {
        $user = User::factory()->create();

        $response = $this->withHeaders($this->authHeaders($user))
            ->postJson('/api/hazards', [
                'incident_latitude'       => 4.7110,
                'incident_longitude'      => -74.0721,
                'impact_radius_meters'    => 150,
                'risk_level_code'         => 'high',
                'category_code'           => 'stagnant_water',
                'estimated_duration_code' => '1_week',
                'description'             => 'Reporte de prueba QA',
                'reported_by_username'    => 'qa_tester',
            ]);

        $response->assertStatus(201)
            ->assertJsonStructure([
                'success',
                'data' => ['id', 'incident_latitude', 'incident_longitude', 'status'],
            ])
            ->assertJsonPath('success', true);
    }

    /**
     * F3-016 extra: POST /api/hazards rechaza solicitudes sin token.
     */
    public function test_create_hazard_without_token_returns_401(): void
    {
        $response = $this->postJson('/api/hazards', [
            'incident_latitude'       => 4.711,
            'incident_longitude'      => -74.072,
            'impact_radius_meters'    => 100,
            'risk_level_code'         => 'low',
            'category_code'           => 'pest_presence',
            'estimated_duration_code' => '1_day',
            'description'             => 'Reporte sin token',
        ]);

        $response->assertStatus(401)
            ->assertJsonPath('success', false)
            ->assertJsonPath('message', 'No autenticado');
    }

    /**
     * F3-017: Eliminar reporte de peligro también elimina sus comentarios asociados
     */
    public function test_delete_hazard_also_deletes_associated_comments(): void
    {
        $user   = User::factory()->create();
        $hazard = HazardReport::factory()->create(['user_id' => $user->id]);

        // Crear comentarios asociados
        ReportComment::create([
            'commentable_type' => HazardReport::class,
            'commentable_id'   => $hazard->id,
            'author_name'      => 'QA User',
            'is_anonymous'     => false,
            'comment_text'     => 'Comentario de prueba',
            'commented_at'     => now(),
            'content_hash'     => md5('QA User|Comentario de prueba'),
        ]);

        $this->assertEquals(1, $hazard->comments()->count());

        $response = $this->withHeaders($this->authHeaders($user))
            ->deleteJson("/api/hazards/{$hazard->id}");

        $response->assertStatus(200);

        // Verificar que comentarios también se eliminaron
        $this->assertEquals(0, ReportComment::where([
            'commentable_type' => HazardReport::class,
            'commentable_id'   => $hazard->id,
        ])->count());
    }

    /**
     * F3-017 extra: Intentar eliminar peligro de otro usuario retorna 403
     */
    public function test_delete_hazard_of_other_user_returns_403(): void
    {
        $owner    = User::factory()->create();
        $attacker = User::factory()->create();
        $hazard   = HazardReport::factory()->create(['user_id' => $owner->id]);

        $response = $this->withHeaders($this->authHeaders($attacker))
            ->deleteJson("/api/hazards/{$hazard->id}");

        $response->assertStatus(403);
    }
}
