<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\CreatesApiToken;
use Tests\TestCase;

class TravelRouteApiTest extends TestCase
{
    use CreatesApiToken;
    use RefreshDatabase;

    public function test_route_crud_flow(): void
    {
        $user = User::factory()->create();
        $headers = $this->authHeaders($user);
        $pointsJson = json_encode([
            ['lat' => 3.4516, 'lng' => -76.5320],
            ['lat' => 3.4600, 'lng' => -76.5400],
        ], JSON_THROW_ON_ERROR);

        $storeResponse = $this->postJson('/api/routes', [
            'local_id' => 'route-local-1',
            'name' => 'Morning Walk',
            'points_json' => $pointsJson,
        ], $headers);

        $routeId = $storeResponse->json('data.id');

        $storeResponse
            ->assertCreated()
            ->assertJsonPath('data.name', 'Morning Walk');

        $this->getJson('/api/routes', $headers)
            ->assertOk()
            ->assertJsonCount(1, 'data');

        $this->putJson('/api/routes/'.$routeId, [
            'name' => 'Morning Walk Updated',
            'points_json' => $pointsJson,
        ], $headers)
            ->assertOk()
            ->assertJsonPath('data.name', 'Morning Walk Updated');

        $this->deleteJson('/api/routes/'.$routeId, [], $headers)
            ->assertOk()
            ->assertJsonPath('success', true);
    }
}
