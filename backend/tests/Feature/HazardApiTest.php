<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\CreatesApiToken;
use Tests\TestCase;

class HazardApiTest extends TestCase
{
    use CreatesApiToken;
    use RefreshDatabase;

    public function test_hazard_listing_store_update_and_comment_flow(): void
    {
        $user = User::factory()->create();
        $headers = $this->authHeaders($user);

        $storeResponse = $this->postJson('/api/hazards', [
            'local_id' => 'hazard-local-1',
            'incident_latitude' => 3.4516,
            'incident_longitude' => -76.5320,
            'impact_radius_meters' => 25,
            'risk_level_code' => 'medium',
            'category_code' => 'waste_accumulation',
            'estimated_duration_code' => '1_week',
            'description' => 'Overflowing trash bin',
            'reported_at' => now()->toIso8601String(),
        ], $headers);

        $hazardId = $storeResponse->json('data.id');

        $storeResponse
            ->assertCreated()
            ->assertJsonPath('data.risk_level_code', 'medium');

        $this->getJson('/api/hazards', $headers)
            ->assertOk()
            ->assertJsonCount(1, 'data');

        $this->putJson('/api/hazards/'.$hazardId, [
            'impact_radius_meters' => 30,
            'risk_level_code' => 'high',
            'description' => 'Overflowing trash bin near the park',
            'last_modified_at' => now()->format('Y-m-d H:i:s'),
        ], $headers)
            ->assertOk()
            ->assertJsonPath('data.risk_level_code', 'high');

        $this->postJson('/api/hazards/'.$hazardId.'/comments', [
            'comment_text' => 'Needs cleanup soon.',
        ], $headers)
            ->assertCreated()
            ->assertJsonPath('data.comment_text', 'Needs cleanup soon.');

        $this->deleteJson('/api/hazards/'.$hazardId, [], $headers)
            ->assertOk()
            ->assertJsonPath('success', true);

        $this->getJson('/api/hazards', $headers)
            ->assertOk()
            ->assertJsonCount(0, 'data');
    }
}
