<?php

namespace Tests\F3\Health;

use Tests\TestCase;

/**
 * F3-001-extra: API health contract for integration regression.
 */
class HealthEndpointTest extends TestCase
{
    public function test_health_endpoint_returns_ok_payload(): void
    {
        $this->getJson('/api/health')
            ->assertStatus(200)
            ->assertJsonPath('status', 'ok')
            ->assertJsonStructure(['status', 'timestamp']);
    }
}
