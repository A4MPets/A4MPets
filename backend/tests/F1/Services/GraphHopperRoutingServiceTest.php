<?php

namespace Tests\F1\Services;

use App\Models\GenericReport;
use App\Models\HazardReport;
use App\Services\GraphHopperRoutingService;
use App\Services\Hazards\HazardRoutingRiskFilter;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Http;
use RuntimeException;
use Tests\TestCase;

/**
 * Pruebas unitarias para GraphHopperRoutingService
 * Casos: F1-025
 */
class GraphHopperRoutingServiceTest extends TestCase
{
    use RefreshDatabase;

    /**
     * F1-025-extra: planRoute lanza RuntimeException cuando no hay URL configurada
     * (o todas las URLs son inalcanzables)
     */
    public function test_plan_route_throws_runtime_exception_when_no_url_configured(): void
    {
        // Configurar sin URL base (cadena vacía)
        Config::set('services.graphhopper.base_url', '');
        Config::set('services.graphhopper.api_key', '');

        // Simular rechazo en todas las URLs que el servicio intenta
        Http::fake([
            'http://graphhopper:8989/*' => Http::response([], 500),
            'http://127.0.0.1:8989/*'   => Http::response([], 500),
        ]);

        $filter  = new HazardRoutingRiskFilter();
        $service = new GraphHopperRoutingService($filter);

        $this->expectException(RuntimeException::class);

        $service->planRoute(
            points: [
                ['lat' => 4.7110, 'lng' => -74.0721],
                ['lat' => 4.7200, 'lng' => -74.0600],
            ],
            avoidHazards: false,
            hazardRiskFilters: null,
            travelMode: 'walk'
        );
    }

    /**
     * F1-025: planRoute construye payload con los puntos en formato correcto [lng, lat]
     * y retorna distancia_meters cuando GraphHopper responde exitosamente
     */
    public function test_plan_route_sends_points_in_correct_format_and_returns_distance(): void
    {
        // Configurar URL de prueba
        Config::set('services.graphhopper.base_url', 'http://graphhopper-test:9999');
        Config::set('services.graphhopper.api_key', '');

        // Simular respuesta exitosa para todas las URLs posibles
        Http::fake([
            'http://graphhopper-test:9999/*' => Http::response([
                'paths' => [
                    [
                        'distance'     => 1500.0,
                        'time'         => 900000,
                        'points'       => ['type' => 'LineString', 'coordinates' => [
                            [-74.0721, 4.7110],
                            [-74.0600, 4.7200],
                        ]],
                        'instructions' => [],
                    ],
                ],
            ], 200),
            // También interceptar fallbacks internos por si acaso
            'http://graphhopper:8989/*' => Http::response([], 500),
            'http://127.0.0.1:8989/*'   => Http::response([], 500),
        ]);

        $filter  = new HazardRoutingRiskFilter();
        $service = new GraphHopperRoutingService($filter);

        $result = $service->planRoute(
            points: [
                ['lat' => 4.7110, 'lng' => -74.0721],
                ['lat' => 4.7200, 'lng' => -74.0600],
            ],
            avoidHazards: false,
            hazardRiskFilters: null,
            travelMode: 'walk'
        );

        // Verifica que devuelve un array con la ruta planeada
        $this->assertIsArray($result);
        $this->assertArrayHasKey('distance_meters', $result);
        $this->assertEquals(1500.0, $result['distance_meters']);
    }

    /**
     * F1-025-extra: vehicle travel mode maps to car and fallback URLs are tried.
     */
    public function test_plan_route_uses_car_profile_api_key_and_fallback_url(): void
    {
        Config::set('services.graphhopper.base_url', 'http://primary-gh:8989');
        Config::set('services.graphhopper.api_key', 'secret key');

        Http::fake([
            'http://primary-gh:8989/*' => Http::response([], 500),
            'http://graphhopper:8989/*' => Http::response([
                'paths' => [[
                    'distance' => 3000,
                    'time' => 600000,
                    'points' => ['coordinates' => [[-74.07, 4.71], [-74.08, 4.72]]],
                    'instructions' => [[
                        'sign' => 0,
                        'text' => 'Continue',
                        'distance' => 20,
                        'time' => 1000,
                        'interval' => [0, 1],
                    ]],
                ]],
            ], 200),
        ]);

        $result = (new GraphHopperRoutingService(new HazardRoutingRiskFilter()))->planRoute(
            points: [
                ['lat' => 4.71, 'lng' => -74.07],
                ['lat' => 4.72, 'lng' => -74.08],
            ],
            avoidHazards: false,
            hazardRiskFilters: [],
            travelMode: 'vehicle'
        );

        $this->assertSame('car', $result['profile']);
        $this->assertSame(600.0, $result['duration_seconds']);
        $this->assertSame('Continue', $result['navigation_instructions'][0]['text']);

        Http::assertSent(fn ($request): bool => str_contains($request->url(), 'key=secret+key')
            && $request['profile'] === 'car');
    }

    /**
     * F1-025-extra: GraphHopper successful HTTP responses without usable paths fail safely.
     */
    public function test_plan_route_throws_when_response_has_no_paths_or_empty_geometry(): void
    {
        Config::set('services.graphhopper.base_url', 'http://graphhopper-empty:8989');
        Config::set('services.graphhopper.api_key', '');

        Http::fake([
            'http://graphhopper-empty:8989/*' => Http::response(['paths' => [[]]], 200),
            'http://graphhopper:8989/*' => Http::response([
                'paths' => [[
                    'points' => ['coordinates' => []],
                ]],
            ], 200),
            'http://127.0.0.1:8989/*' => Http::response([], 500),
        ]);

        $this->expectException(RuntimeException::class);
        $this->expectExceptionMessage('No se pudo calcular la ruta');

        (new GraphHopperRoutingService(new HazardRoutingRiskFilter()))->planRoute(
            points: [
                ['lat' => 4.71, 'lng' => -74.07],
                ['lat' => 4.72, 'lng' => -74.08],
            ],
            avoidHazards: false,
            hazardRiskFilters: null,
            travelMode: 'walking'
        );
    }

    /**
     * F1-025-extra: hazard avoidance adds GraphHopper custom model areas.
     */
    public function test_plan_route_adds_custom_model_when_avoiding_selected_hazards(): void
    {
        HazardReport::factory()->create([
            'incident_latitude' => 4.715,
            'incident_longitude' => -74.075,
            'impact_radius_meters' => 80,
            'risk_level_code' => 'high',
            'status' => 'created',
        ]);
        GenericReport::create([
            'latitude' => 4.716,
            'longitude' => -74.076,
            'description' => 'Otro riesgo',
            'reported_date' => now(),
            'risk_level_code' => 'medium',
            'impact_radius_meters' => 40,
        ]);

        Config::set('services.graphhopper.base_url', 'http://graphhopper-avoid:8989');
        Config::set('services.graphhopper.api_key', '');

        Http::fake([
            'http://graphhopper-avoid:8989/*' => Http::response([
                'paths' => [[
                    'distance' => 1000,
                    'time' => 120000,
                    'points' => ['coordinates' => [[-74.07, 4.71], [-74.08, 4.72]]],
                    'instructions' => [],
                ]],
            ], 200),
        ]);

        $result = (new GraphHopperRoutingService(new HazardRoutingRiskFilter()))->planRoute(
            points: [
                ['lat' => 4.71, 'lng' => -74.07],
                ['lat' => 4.72, 'lng' => -74.08],
            ],
            avoidHazards: true,
            hazardRiskFilters: ['high', 'other'],
            travelMode: 'walking'
        );

        $this->assertSame(2, $result['hazards_considered']);
        $this->assertSame(['high', 'other'], $result['hazard_risk_filters']);

        Http::assertSent(fn ($request): bool => str_contains($request->url(), 'ch.disable=true')
            && isset($request['custom_model']['areas'])
            && count($request['custom_model']['priority']) === 2);
    }
}
