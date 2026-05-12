<?php

namespace Tests\F3\Routes;

use App\Models\GenericReport;
use App\Models\HazardReport;
use App\Models\TravelRoute;
use App\Models\User;
use App\Services\GraphHopperRoutingService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Mockery;
use RuntimeException;
use Tests\Concerns\CreatesApiToken;
use Tests\TestCase;

/**
 * F3-019/F3-024-extra: Travel route and route planning controller coverage.
 */
class TravelRouteAndPlanningControllerTest extends TestCase
{
    use RefreshDatabase, CreatesApiToken;

    public function test_owner_can_list_show_create_update_and_delete_travel_route(): void
    {
        $user = User::factory()->create();

        $create = $this->withHeaders($this->authHeaders($user))
            ->postJson('/api/routes', [
                'name' => 'Ruta feature',
                'points_json' => json_encode([
                    ['lat' => 4.71, 'lng' => -74.07],
                    ['lat' => 4.72, 'lng' => -74.08],
                ]),
            ]);

        $create->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.name', 'Ruta feature');
        $routeId = $create->json('data.id');

        $this->getJson('/api/routes?per_page=5')
            ->assertStatus(200)
            ->assertJsonPath('success', true);
        $this->getJson("/api/routes/{$routeId}")
            ->assertStatus(200)
            ->assertJsonPath('data.id', $routeId);

        $this->withHeaders($this->authHeaders($user))
            ->putJson("/api/routes/{$routeId}", [
                'name' => 'Ruta feature actualizada',
                'points_json' => json_encode([['lat' => 4.73, 'lng' => -74.09]]),
            ])
            ->assertStatus(200)
            ->assertJsonPath('data.name', 'Ruta feature actualizada');

        $route = TravelRoute::query()->with('routePoints')->findOrFail($routeId);
        $this->assertTrue($route->user()->is($user));
        $this->assertSame(1, $user->routes()->whereKey($routeId)->count());
        $this->assertSame(1, $route->routePoints()->count());
        $this->assertTrue($route->routePoints->first()->route()->is($route));

        $this->withHeaders($this->authHeaders($user))
            ->deleteJson("/api/routes/{$routeId}")
            ->assertStatus(200);
    }

    public function test_non_owner_route_mutation_and_invalid_payload_are_rejected(): void
    {
        $owner = User::factory()->create();
        $other = User::factory()->create();
        $route = TravelRoute::create([
            'user_id' => $owner->id,
            'name' => 'Ruta privada',
            'points_json' => '[]',
        ]);

        $this->withHeaders($this->authHeaders($other))
            ->putJson("/api/routes/{$route->id}", [
                'name' => 'No autorizado',
                'points_json' => '[]',
            ])
            ->assertStatus(403);

        $this->withHeaders($this->authHeaders($owner))
            ->postJson('/api/routes', [
                'points_json' => '[]',
            ])
            ->assertStatus(422);
    }

    public function test_routes_index_without_token_returns_401(): void
    {
        $this->getJson('/api/routes?per_page=5')
            ->assertStatus(401)
            ->assertJsonPath('success', false)
            ->assertJsonPath('message', 'No autenticado');
    }

    public function test_route_planning_returns_success_and_validation_error(): void
    {
        $user = User::factory()->create();

        $this->mock(GraphHopperRoutingService::class, function ($mock): void {
            $mock->shouldReceive('planRoute')
                ->once()
                ->andReturn([
                    'coordinates' => [[-74.07, 4.71], [-74.08, 4.72]],
                    'distance_meters' => 1000.0,
                    'duration_seconds' => 120.0,
                    'profile' => 'foot',
                    'hazards_considered' => 0,
                    'hazard_risk_filters' => ['low'],
                    'navigation_instructions' => [],
                ]);
        });

        $this->withHeaders($this->authHeaders($user))
            ->postJson('/api/routes/plan', [
                'points' => [
                    ['lat' => 4.71, 'lng' => -74.07],
                    ['lat' => 4.72, 'lng' => -74.08],
                ],
                'avoid_hazards' => true,
                'hazard_risk_filters' => ['low'],
                'travel_mode' => 'walking',
                'trip_config' => ['pets' => 1],
            ])
            ->assertStatus(200)
            ->assertJsonPath('data.profile', 'foot')
            ->assertJsonPath('meta.travel_mode', 'walking');

        $this->withHeaders($this->authHeaders($user))
            ->postJson('/api/routes/plan', [
                'points' => [['lat' => 4.71, 'lng' => -74.07]],
            ])
            ->assertStatus(422);

    }

    public function test_route_planning_without_token_returns_401(): void
    {
        $this->postJson('/api/routes/plan', [
            'points' => [
                ['lat' => 4.71, 'lng' => -74.07],
                ['lat' => 4.72, 'lng' => -74.08],
            ],
        ])
            ->assertStatus(401)
            ->assertJsonPath('success', false)
            ->assertJsonPath('message', 'No autenticado');
    }

    public function test_route_planning_returns_502_when_graphhopper_fails(): void
    {
        $user = User::factory()->create();
        $this->instance(GraphHopperRoutingService::class, Mockery::mock(GraphHopperRoutingService::class, function ($mock): void {
            $mock->shouldReceive('planRoute')->once()->andThrow(new RuntimeException('GraphHopper down'));
        }));

        $this->withHeaders($this->authHeaders($user))
            ->postJson('/api/routes/plan', [
                'points' => [
                    ['lat' => 4.71, 'lng' => -74.07],
                    ['lat' => 4.72, 'lng' => -74.08],
                ],
            ])
            ->assertStatus(502)
            ->assertJsonPath('success', false);
    }

    public function test_route_planning_uses_real_graphhopper_service_with_http_fake_and_hazard_avoidance(): void
    {
        $user = User::factory()->create();
        config()->set('services.graphhopper.base_url', 'http://graphhopper-f3.test');
        config()->set('services.graphhopper.api_key', 'f3-key');

        HazardReport::factory()->create([
            'incident_latitude' => 4.7105,
            'incident_longitude' => -74.0705,
            'impact_radius_meters' => 120,
            'risk_level_code' => 'high',
            'status' => 'created',
        ]);
        HazardReport::factory()->create([
            'incident_latitude' => 4.7110,
            'incident_longitude' => -74.0710,
            'impact_radius_meters' => 120,
            'risk_level_code' => 'low',
            'status' => 'created',
        ]);
        GenericReport::create([
            'latitude' => 4.7120,
            'longitude' => -74.0720,
            'description' => 'Obstaculo temporal F3',
            'reported_date' => now(),
            'risk_level_code' => 'medium',
            'impact_radius_meters' => 80,
        ]);

        Http::fake([
            'graphhopper-f3.test/route*' => Http::response([
                'paths' => [[
                    'distance' => 1550.25,
                    'time' => 420000,
                    'points' => [
                        'coordinates' => [
                            [-74.07, 4.71],
                            [-74.08, 4.72],
                        ],
                    ],
                    'instructions' => [[
                        'sign' => 2,
                        'text' => 'Gire a la derecha',
                        'street_name' => 'Calle F3',
                        'exit_number' => 3,
                        'distance' => 120.5,
                        'time' => 30000,
                        'interval' => [0, 1],
                    ]],
                ]],
            ], 200),
        ]);

        $this->withHeaders($this->authHeaders($user))
            ->postJson('/api/routes/plan', [
                'points' => [
                    ['lat' => 4.71, 'lng' => -74.07],
                    ['lat' => 4.72, 'lng' => -74.08],
                ],
                'avoid_hazards' => true,
                'hazard_risk_filters' => ['high', 'other', 'high'],
                'travel_mode' => 'vehicle',
                'trip_config' => ['pets' => [10, 20]],
            ])
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.profile', 'car')
            ->assertJsonPath('data.used_hazard_avoidance', true)
            ->assertJsonPath('data.hazards_considered', 2)
            ->assertJsonPath('data.navigation_instructions.0.sequence', 0)
            ->assertJsonPath('data.navigation_instructions.0.duration_seconds', 30)
            ->assertJsonPath('meta.hazard_risk_filters', ['high', 'other'])
            ->assertJsonPath('meta.trip_config.pets', [10, 20]);

        Http::assertSent(function ($request): bool {
            $payload = $request->data();

            return str_contains((string) $request->url(), 'ch.disable=true')
                && str_contains((string) $request->url(), 'key=f3-key')
                && ($payload['profile'] ?? null) === 'car'
                && ($payload['points'] ?? null) === [[-74.07, 4.71], [-74.08, 4.72]]
                && isset($payload['custom_model']['areas'], $payload['custom_model']['priority'])
                && count($payload['custom_model']['priority']) === 2;
        });
    }

    public function test_route_planning_real_service_falls_back_to_second_graphhopper_url(): void
    {
        $user = User::factory()->create();
        config()->set('services.graphhopper.base_url', 'http://graphhopper-primary-f3.test');
        config()->set('services.graphhopper.api_key', '');

        Http::fake([
            'graphhopper-primary-f3.test/route*' => Http::response(['message' => 'busy'], 500),
            'graphhopper:8989/route*' => Http::response([
                'paths' => [[
                    'distance' => 900,
                    'time' => 180000,
                    'points' => [
                        'coordinates' => [
                            [-74.07, 4.71],
                            [-74.075, 4.715],
                        ],
                    ],
                    'instructions' => [],
                ]],
            ], 200),
        ]);

        $this->withHeaders($this->authHeaders($user))
            ->postJson('/api/routes/plan', [
                'points' => [
                    ['lat' => 4.71, 'lng' => -74.07],
                    ['lat' => 4.715, 'lng' => -74.075],
                ],
                'avoid_hazards' => false,
                'travel_mode' => 'walking',
            ])
            ->assertStatus(200)
            ->assertJsonPath('data.profile', 'foot')
            ->assertJsonPath('data.hazards_considered', 0)
            ->assertJsonPath('data.duration_seconds', 180);

        Http::assertSentCount(2);
    }
}
