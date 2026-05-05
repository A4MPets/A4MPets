<?php

namespace Tests\Feature;

use App\Models\GenericReport;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\CreatesApiToken;
use Tests\TestCase;

class GenericReportApiTest extends TestCase
{
    use CreatesApiToken;
    use RefreshDatabase;

    public function test_generic_report_store_update_and_comments_keep_impact_radius(): void
    {
        $user = User::factory()->create();
        $headers = $this->authHeaders($user);

        $storeResponse = $this->postJson('/api/generic-reports', [
            'latitude' => 3.4516,
            'longitude' => -76.5320,
            'description' => 'Loose cable near the sidewalk',
            'reported_date' => now()->toIso8601String(),
            'risk_level_code' => 'medium',
            'impact_radius_meters' => 45,
            'photo_url' => 'https://example.com/generic-1.jpg',
        ], $headers);

        $genericReportId = $storeResponse->json('data.id');

        $storeResponse
            ->assertCreated()
            ->assertJsonPath('data.impact_radius_meters', 45)
            ->assertJsonPath('data.reported_by_username', $user->name);

        $this->getJson('/api/generic-reports', $headers)
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.impact_radius_meters', 45);

        $this->putJson('/api/generic-reports/'.$genericReportId, [
            'latitude' => 3.4516,
            'longitude' => -76.5320,
            'description' => 'Loose cable secured',
            'reported_date' => now()->toIso8601String(),
            'risk_level_code' => 'low',
            'impact_radius_meters' => 0,
            'photo_url' => 'https://example.com/generic-1.jpg',
        ], $headers)
            ->assertOk()
            ->assertJsonPath('data.impact_radius_meters', 0);

        $this->postJson('/api/generic-reports/'.$genericReportId.'/comments', [
            'comment_text' => 'This zone still looks risky.',
        ], $headers)
            ->assertCreated()
            ->assertJsonPath('data.comment_text', 'This zone still looks risky.');

        $this->getJson('/api/generic-reports/'.$genericReportId.'/comments', $headers)
            ->assertOk()
            ->assertJsonPath('data.0.comment_text', 'This zone still looks risky.');

        $this->deleteJson('/api/generic-reports/'.$genericReportId, [], $headers)
            ->assertOk()
            ->assertJsonPath('success', true);

        $this->getJson('/api/generic-reports', $headers)
            ->assertOk()
            ->assertJsonCount(0, 'data');
    }

    public function test_generic_report_can_be_created_anonymously(): void
    {
        $this->postJson('/api/generic-reports', [
            'latitude' => 3.4516,
            'longitude' => -76.5320,
            'description' => 'Loose cable near the sidewalk',
            'reported_date' => now()->toIso8601String(),
            'risk_level_code' => 'medium',
            'impact_radius_meters' => 45,
            'photo_url' => 'https://example.com/generic-1.jpg',
        ])
            ->assertCreated()
            ->assertJsonPath('data.user_id', null)
            ->assertJsonPath('data.reported_by_username', 'Anonimo');

        $genericReport = GenericReport::query()->firstOrFail();
        $this->assertNull($genericReport->user_id);
    }
}
