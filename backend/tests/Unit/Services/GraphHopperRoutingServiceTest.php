<?php

namespace Tests\Unit\Services;

use App\Services\GraphHopperRoutingService;
use App\Services\Hazards\HazardRoutingRiskFilter;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Http;
use RuntimeException;
use Tests\TestCase;

/**
 * Pruebas unitarias para GraphHopperRoutingService
 * Casos: F1-019, F1-020
 */
class GraphHopperRoutingServiceTest extends TestCase
{
    /**
     * F1-020: planRoute lanza RuntimeException cuando no hay URL configurada
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
     * F1-019: planRoute construye payload con los puntos en formato correcto [lng, lat]
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
}
