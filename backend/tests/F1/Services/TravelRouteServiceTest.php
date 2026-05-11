<?php

namespace Tests\F1\Services;

use App\Models\TravelRoute;
use App\Models\User;
use App\Services\Routes\TravelRouteService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Pruebas unitarias para TravelRouteService
 * Casos: F1-024
 */
class TravelRouteServiceTest extends TestCase
{
    use RefreshDatabase;

    private TravelRouteService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = new TravelRouteService();
    }

    /**
     * F1-024: store crea una ruta con nombre y puntos JSON válidos
     * Nota: TravelRoute usa la tabla 'routes' y points_json es un atributo virtual
     * calculado desde la tabla route_points (relación HasMany)
     */
    public function test_store_creates_travel_route_with_name_and_points(): void
    {
        $user = User::factory()->create();

        $points = json_encode([
            ['lat' => 4.711, 'lng' => -74.072],
            ['lat' => 4.720, 'lng' => -74.060],
        ]);

        $route = $this->service->store($user->id, [
            'name'        => 'Ruta QA Principal',
            'points_json' => $points,
        ]);

        $this->assertInstanceOf(TravelRoute::class, $route);
        $this->assertEquals('Ruta QA Principal', $route->name);
        $this->assertEquals($user->id, $route->user_id);

        // La tabla del modelo TravelRoute se llama 'routes'
        $this->assertDatabaseHas('routes', [
            'id'      => $route->id,
            'user_id' => $user->id,
            'name'    => 'Ruta QA Principal',
        ]);

        // Los puntos se almacenan en route_points, verifica que se crearon
        $this->assertDatabaseHas('route_points', [
            'route_id' => $route->id,
            'sequence' => 0,
            'latitude'  => 4.711,
            'longitude' => -74.072,
        ]);
    }

    /**
     * F1-024 extra: canMutate valida propiedad de ruta correctamente
     */
    public function test_can_mutate_returns_true_for_owner_and_false_for_other(): void
    {
        $owner = User::factory()->create();
        $other = User::factory()->create();

        $route = $this->service->store($owner->id, [
            'name'        => 'Ruta propietario',
            'points_json' => '[]',
        ]);

        $this->assertTrue($this->service->canMutate($owner->id, $route));
        $this->assertFalse($this->service->canMutate($other->id, $route));
        $this->assertFalse($this->service->canMutate(null, $route));
    }

    /**
     * F1-024 extra: delete elimina la ruta correctamente
     */
    public function test_delete_removes_travel_route(): void
    {
        $user  = User::factory()->create();
        $route = $this->service->store($user->id, [
            'name'        => 'Ruta a eliminar',
            'points_json' => '[]',
        ]);

        $routeId = $route->id;
        $this->service->delete($route);

        $this->assertDatabaseMissing('routes', ['id' => $routeId]);
    }
}
