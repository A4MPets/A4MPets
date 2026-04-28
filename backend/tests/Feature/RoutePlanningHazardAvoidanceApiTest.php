<?php

namespace Tests\Feature;

use App\Models\GenericReport;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\Concerns\CreatesApiToken;
use Tests\TestCase;

class RoutePlanningHazardAvoidanceApiTest extends TestCase
{
    use CreatesApiToken;
    use RefreshDatabase;

    public function test_route_planning_uses_generic_report_pet_danger_radius(): void
    {
        $user = User::factory()->create();
        $headers = $this->authHeaders($user);

        GenericReport::create([
            'user_id' => $user->id,
            'local_id' => 'generic-route-1',
            'latitude' => 3.4516,
            'longitude' => -76.5320,
            'description' => 'Sharp debris near the route',
            'reported_date' => now(),
            'risk_level_code' => 'medium',
            'impact_radius_meters' => 60,
            'photo_url' => null,
            'sync_status' => 'synced',
            'last_modified_at' => now(),
            'synced_at' => now(),
        ]);

        GenericReport::create([
            'user_id' => $user->id,
            'local_id' => 'generic-route-2',
            'latitude' => 3.4518,
            'longitude' => -76.5322,
            'description' => 'Informational report only',
            'reported_date' => now(),
            'risk_level_code' => 'low',
            'impact_radius_meters' => 0,
            'photo_url' => null,
            'sync_status' => 'synced',
            'last_modified_at' => now(),
            'synced_at' => now(),
        ]);

        Http::fake([
            '*' => Http::response([
                'paths' => [
                    [
                        'distance' => 1200.0,
                        'time' => 900000.0,
                        'points' => [
                            'coordinates' => [
                                [-76.5320, 3.4516],
                                [-76.5400, 3.4600],
                            ],
                        ],
                    ],
                ],
            ], 200),
        ]);

        $response = $this->postJson('/api/routes/plan', [
            'points' => [
                ['lat' => 3.4516, 'lng' => -76.5320],
                ['lat' => 3.4600, 'lng' => -76.5400],
            ],
            'avoid_hazards' => true,
            'travel_mode' => 'walking',
        ], $headers);

        $response
            ->assertOk()
            ->assertJsonPath('data.used_hazard_avoidance', true)
            ->assertJsonPath('data.hazards_considered', 1);

        Http::assertSent(function ($request): bool {
            $data = $request->data();
            $areas = $data['custom_model']['areas'] ?? [];

            return count($areas) === 1;
        });
    }
}
