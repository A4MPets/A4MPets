<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\CreatesApiToken;
use Tests\TestCase;

class LostPetReportSyncApiTest extends TestCase
{
    use CreatesApiToken;
    use RefreshDatabase;

    public function test_lost_pet_sync_handles_synced_and_deleted_items(): void
    {
        $user = User::factory()->create();
        $headers = $this->authHeaders($user);

        $response = $this->postJson('/api/lost-pet-reports/sync', [
            'lost_pet_reports' => [
                [
                    'local_id' => 'lost-1',
                    'remote_id' => null,
                    'last_seen_latitude' => 3.4516,
                    'last_seen_longitude' => -76.5320,
                    'name' => 'Milo',
                    'details' => 'Brown dog with blue collar',
                    'disappearance_date' => now()->subDay()->format('Y-m-d H:i:s'),
                    'photo_url' => null,
                    'phone' => '5551234',
                    'sync_status' => 'synced',
                    'last_modified_at' => now()->format('Y-m-d H:i:s'),
                ],
                [
                    'local_id' => 'lost-2',
                    'remote_id' => null,
                    'last_seen_latitude' => 3.4517,
                    'last_seen_longitude' => -76.5321,
                    'name' => 'Nina',
                    'details' => 'White cat',
                    'disappearance_date' => now()->subDays(2)->format('Y-m-d H:i:s'),
                    'photo_url' => null,
                    'phone' => null,
                    'sync_status' => 'deleted',
                    'last_modified_at' => now()->format('Y-m-d H:i:s'),
                ],
            ],
        ], $headers);

        $response
            ->assertOk()
            ->assertJsonPath('sync_results.synced', 1)
            ->assertJsonPath('sync_results.deleted', 1)
            ->assertJsonPath('sync_results.errors', 0);
    }
}
