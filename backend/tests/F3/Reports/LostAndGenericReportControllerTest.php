<?php

namespace Tests\F3\Reports;

use App\Models\GenericReport;
use App\Models\LostPetReport;
use App\Models\Pet;
use App\Models\ReportComment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\CreatesApiToken;
use Tests\TestCase;

/**
 * F3-023-extra: Feature coverage for lost and generic report controllers.
 */
class LostAndGenericReportControllerTest extends TestCase
{
    use RefreshDatabase, CreatesApiToken;

    public function test_lost_pet_report_owner_can_crud_and_comment(): void
    {
        $user = User::factory()->create();
        $pet = Pet::factory()->create(['user_id' => $user->id, 'status' => 'normal']);

        $create = $this->withHeaders($this->authHeaders($user))
            ->postJson('/api/lost-pet-reports', [
                'pet_id' => $pet->id,
                'last_seen_latitude' => 4.71,
                'last_seen_longitude' => -74.07,
                'details' => 'Mascota perdida desde feature',
                'disappearance_date' => '2026-05-08 09:00:00',
                'phone' => '300',
            ]);

        $create->assertStatus(201)->assertJsonPath('success', true);
        $reportId = $create->json('data.id');

        $this->getJson('/api/lost-pet-reports?per_page=5')
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['pagination' => ['total', 'per_page', 'current_page', 'last_page']]);

        $this->getJson("/api/lost-pet-reports/{$reportId}")
            ->assertStatus(200)
            ->assertJsonPath('data.id', $reportId);

        $this->withHeaders($this->authHeaders($user))
            ->postJson("/api/lost-pet-reports/{$reportId}/comments", [
                'comment_text' => 'Lo vi cerca del parque',
                'is_anonymous' => false,
            ])
            ->assertStatus(201)
            ->assertJsonPath('data.comment_text', 'Lo vi cerca del parque');

        $this->getJson("/api/lost-pet-reports/{$reportId}/comments")
            ->assertStatus(200)
            ->assertJsonCount(1, 'data');

        $this->withHeaders($this->authHeaders($user))
            ->putJson("/api/lost-pet-reports/{$reportId}", [
                'pet_id' => $pet->id,
                'last_seen_latitude' => 4.72,
                'last_seen_longitude' => -74.08,
                'details' => 'Mascota perdida actualizada',
                'disappearance_date' => '2026-05-08 10:00:00',
                'phone' => '301',
            ])
            ->assertStatus(200)
            ->assertJsonPath('data.details', 'Mascota perdida actualizada');

        $this->withHeaders($this->authHeaders($user))
            ->deleteJson("/api/lost-pet-reports/{$reportId}")
            ->assertStatus(200)
            ->assertJsonPath('success', true);
    }

    public function test_lost_pet_report_rejects_guest_store_and_non_owner_mutation(): void
    {
        $owner = User::factory()->create();
        $other = User::factory()->create();
        $pet = Pet::factory()->create(['user_id' => $owner->id]);
        $report = LostPetReport::factory()->create(['user_id' => $owner->id, 'pet_id' => $pet->id]);

        $this->postJson('/api/lost-pet-reports', [
            'pet_id' => $pet->id,
            'last_seen_latitude' => 4.71,
            'last_seen_longitude' => -74.07,
            'details' => 'Sin auth',
            'disappearance_date' => now()->toDateTimeString(),
            'phone' => '300',
        ])->assertStatus(401);

        $this->withHeaders($this->authHeaders($other))
            ->putJson("/api/lost-pet-reports/{$report->id}", [
                'pet_id' => $pet->id,
                'last_seen_latitude' => 4.72,
                'last_seen_longitude' => -74.08,
                'details' => 'No autorizado',
                'disappearance_date' => now()->toDateTimeString(),
                'phone' => '301',
            ])
            ->assertStatus(403);
    }

    public function test_generic_report_guest_and_owner_paths_are_covered(): void
    {
        $owner = User::factory()->create();
        $other = User::factory()->create();

        $guestCreate = $this->postJson('/api/generic-reports', [
            'latitude' => 4.71,
            'longitude' => -74.07,
            'description' => 'Reporte generico invitado',
            'reported_date' => '2026-05-08 09:00:00',
            'risk_level_code' => 'invalid-risk',
            'impact_radius_meters' => 30,
        ]);
        $guestCreate->assertStatus(201)
            ->assertJsonPath('data.risk_level_code', 'undefined');

        $report = GenericReport::create([
            'user_id' => $owner->id,
            'latitude' => 4.72,
            'longitude' => -74.08,
            'description' => 'Reporte generico propietario',
            'reported_date' => now(),
            'risk_level_code' => 'medium',
            'impact_radius_meters' => 45,
        ]);

        $this->getJson('/api/generic-reports?per_page=5')
            ->assertStatus(200)
            ->assertJsonPath('success', true);
        $this->getJson("/api/generic-reports/{$report->id}")
            ->assertStatus(200)
            ->assertJsonPath('data.id', $report->id);

        $this->withHeaders($this->authHeaders($owner))
            ->postJson("/api/generic-reports/{$report->id}/comments", [
                'comment_text' => 'Comentario generico',
            ])
            ->assertStatus(201);
        $this->getJson("/api/generic-reports/{$report->id}/comments")
            ->assertStatus(200)
            ->assertJsonCount(1, 'data');

        $this->withHeaders($this->authHeaders($other))
            ->putJson("/api/generic-reports/{$report->id}", [
                'latitude' => 4.73,
                'longitude' => -74.09,
                'description' => 'Ataque',
                'reported_date' => now()->toDateTimeString(),
                'risk_level_code' => 'high',
            ])
            ->assertStatus(403);

        $this->withHeaders($this->authHeaders($owner))
            ->putJson("/api/generic-reports/{$report->id}", [
                'latitude' => 4.74,
                'longitude' => -74.10,
                'description' => 'Actualizado',
                'reported_date' => now()->toDateTimeString(),
                'risk_level_code' => 'high',
            ])
            ->assertStatus(200)
            ->assertJsonPath('data.description', 'Actualizado');

        $this->withHeaders($this->authHeaders($owner))
            ->deleteJson("/api/generic-reports/{$report->id}")
            ->assertStatus(200);
    }
}
