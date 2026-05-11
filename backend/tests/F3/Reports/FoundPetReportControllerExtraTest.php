<?php

namespace Tests\F3\Reports;

use App\Models\FoundPetReport;
use App\Models\Pet;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\CreatesApiToken;
use Tests\TestCase;

/**
 * F3-025-extra: Additional found pet report controller coverage.
 */
class FoundPetReportControllerExtraTest extends TestCase
{
    use RefreshDatabase, CreatesApiToken;

    public function test_owner_can_list_show_update_comment_and_delete_found_report(): void
    {
        $user = User::factory()->create();
        $pet = Pet::factory()->ownerless()->create();
        $report = FoundPetReport::create([
            'user_id' => $user->id,
            'pet_id' => $pet->id,
            'latitude' => 4.71,
            'longitude' => -74.07,
            'details' => 'Encontrada',
            'found_date' => now(),
        ]);

        $this->getJson('/api/found-pet-reports?per_page=5')
            ->assertStatus(200)
            ->assertJsonPath('success', true);
        $this->getJson("/api/found-pet-reports/{$report->id}")
            ->assertStatus(200)
            ->assertJsonPath('data.id', $report->id);

        $this->withHeaders($this->authHeaders($user))
            ->postJson("/api/found-pet-reports/{$report->id}/comments", [
                'comment_text' => 'La puedo resguardar',
                'is_anonymous' => false,
            ])
            ->assertStatus(201)
            ->assertJsonPath('data.comment_text', 'La puedo resguardar');
        $this->getJson("/api/found-pet-reports/{$report->id}/comments")
            ->assertStatus(200)
            ->assertJsonCount(1, 'data');

        $this->withHeaders($this->authHeaders($user))
            ->putJson("/api/found-pet-reports/{$report->id}", [
                'pet_id' => $pet->id,
                'latitude' => 4.72,
                'longitude' => -74.08,
                'details' => 'Encontrada actualizada',
                'found_date' => '2026-05-08 12:00:00',
            ])
            ->assertStatus(200)
            ->assertJsonPath('data.details', 'Encontrada actualizada');

        $this->withHeaders($this->authHeaders($user))
            ->deleteJson("/api/found-pet-reports/{$report->id}")
            ->assertStatus(200);
    }

    public function test_found_report_non_owner_update_and_delete_are_forbidden(): void
    {
        $owner = User::factory()->create();
        $other = User::factory()->create();
        $pet = Pet::factory()->ownerless()->create();
        $report = FoundPetReport::create([
            'user_id' => $owner->id,
            'pet_id' => $pet->id,
            'latitude' => 4.71,
            'longitude' => -74.07,
            'details' => 'Encontrada',
            'found_date' => now(),
        ]);

        $this->withHeaders($this->authHeaders($other))
            ->putJson("/api/found-pet-reports/{$report->id}", [
                'pet_id' => $pet->id,
                'latitude' => 4.72,
                'longitude' => -74.08,
                'details' => 'No autorizado',
                'found_date' => now()->toDateTimeString(),
            ])
            ->assertStatus(403);

        $this->withHeaders($this->authHeaders($other))
            ->deleteJson("/api/found-pet-reports/{$report->id}")
            ->assertStatus(403);
    }
}
