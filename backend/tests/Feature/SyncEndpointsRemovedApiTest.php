<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SyncEndpointsRemovedApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_sync_endpoints_are_not_registered(): void
    {
        foreach ([
            '/api/hazards/sync',
            '/api/lost-pet-reports/sync',
            '/api/found-pet-reports/sync',
            '/api/generic-reports/sync',
            '/api/pets/sync',
            '/api/routes/sync',
        ] as $path) {
            $this->postJson($path)->assertStatus(405);
        }
    }
}
