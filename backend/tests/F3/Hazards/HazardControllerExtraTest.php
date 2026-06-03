<?php

namespace Tests\F3\Hazards;

use App\Models\HazardReport;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\CreatesApiToken;
use Tests\TestCase;

/**
 * F3-016/F3-017-extra: Additional HazardReportController coverage.
 */
class HazardControllerExtraTest extends TestCase
{
    use RefreshDatabase, CreatesApiToken;

    public function test_index_show_update_and_comments_are_covered(): void
    {
        $user = User::factory()->create();
        $hazard = HazardReport::factory()->create([
            'user_id' => $user->id,
            'risk_level_code' => 'medium',
            'category_code' => 'pest_presence',
            'estimated_duration_code' => '1_day',
        ]);

        $this->getJson('/api/hazards?risk_level=medium&latitude=4.7&longitude=-74.0&radius_km=500')
            ->assertStatus(200)
            ->assertJsonPath('success', true);

        $this->getJson("/api/hazards/{$hazard->id}")
            ->assertStatus(200)
            ->assertJsonPath('data.id', $hazard->id);

        $this->withHeaders($this->authHeaders($user))
            ->putJson("/api/hazards/{$hazard->id}", [
                'risk_level_code' => 'low',
                'description' => 'Peligro actualizado',
            ])
            ->assertStatus(200)
            ->assertJsonPath('data.risk_level_code', 'low');

        $this->withHeaders($this->authHeaders($user))
            ->postJson("/api/hazards/{$hazard->id}/comments", [
                'comment_text' => 'Comentario peligro',
                'is_anonymous' => false,
            ])
            ->assertStatus(201)
            ->assertJsonPath('data.comment_text', 'Comentario peligro');

        $this->getJson("/api/hazards/{$hazard->id}/comments")
            ->assertStatus(200)
            ->assertJsonCount(1, 'data');

        $this->assertTrue($hazard->fresh()->user()->is($user));
        $this->assertSame(1, $user->hazardReports()->whereKey($hazard->id)->count());
    }

    public function test_hazard_update_rejects_non_owner_and_validation_errors(): void
    {
        $owner = User::factory()->create();
        $other = User::factory()->create();
        $hazard = HazardReport::factory()->create(['user_id' => $owner->id]);

        $this->withHeaders($this->authHeaders($other))
            ->putJson("/api/hazards/{$hazard->id}", [
                'description' => 'No autorizado',
            ])
            ->assertStatus(403);

        $this->postJson('/api/hazards', [
            'incident_latitude' => 200,
            'incident_longitude' => -74.07,
            'impact_radius_meters' => 1,
            'risk_level_code' => 'high',
        ])->assertStatus(422);
    }

    public function test_guest_can_add_anonymous_hazard_comment(): void
    {
        $hazard = HazardReport::factory()->create();

        $this->postJson("/api/hazards/{$hazard->id}/comments", [
            'comment_text' => 'Comentario anonimo de peligro',
            'is_anonymous' => true,
        ])
            ->assertStatus(201)
            ->assertJsonPath('data.user_id', null)
            ->assertJsonPath('data.author_username', 'Anonimo')
            ->assertJsonPath('data.is_anonymous', true)
            ->assertJsonPath('data.comment_text', 'Comentario anonimo de peligro');

        $this->getJson("/api/hazards/{$hazard->id}/comments")
            ->assertStatus(200)
            ->assertJsonCount(1, 'data');
    }

    public function test_authenticated_user_can_delete_anonymous_hazard(): void
    {
        $user = User::factory()->create();
        $hazard = HazardReport::factory()->create(['user_id' => null]);

        $this->withHeaders($this->authHeaders($user))
            ->deleteJson("/api/hazards/{$hazard->id}")
            ->assertStatus(200)
            ->assertJsonPath('success', true);

        $this->assertDatabaseMissing('hazard_reports', ['id' => $hazard->id]);
    }
}
