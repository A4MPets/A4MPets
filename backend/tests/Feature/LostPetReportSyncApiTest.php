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
        $pet = $this->postJson('/api/pets', [
            'local_id' => 'pet-local-1',
            'local_uuid' => 'pet-local-1',
            'name' => 'Milo',
            'photo_path' => 'https://example.com/pet.jpg',
        ], $headers)->json('data');

        $response = $this->postJson('/api/lost-pet-reports/sync', [
            'lost_pet_reports' => [
                [
                    'local_id' => 'lost-1',
                    'remote_id' => null,
                    'pet_local_uuid' => $pet['local_uuid'],
                    'last_seen_latitude' => 3.4516,
                    'last_seen_longitude' => -76.5320,
                    'details' => 'Brown dog with blue collar',
                    'disappearance_date' => now()->subDay()->format('Y-m-d H:i:s'),
                    'photo_url' => 'https://example.com/lost-1.jpg',
                    'phone' => '5551234',
                    'sync_status' => 'synced',
                    'last_modified_at' => now()->format('Y-m-d H:i:s'),
                ],
                [
                    'local_id' => 'lost-2',
                    'remote_id' => null,
                    'pet_local_uuid' => $pet['local_uuid'],
                    'last_seen_latitude' => 3.4517,
                    'last_seen_longitude' => -76.5321,
                    'details' => 'White cat',
                    'disappearance_date' => now()->subDays(2)->format('Y-m-d H:i:s'),
                    'photo_url' => 'https://example.com/lost-2.jpg',
                    'phone' => '5554321',
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

    public function test_lost_pet_sync_requires_phone(): void
    {
        $user = User::factory()->create();
        $headers = $this->authHeaders($user);

        $response = $this->postJson('/api/lost-pet-reports/sync', [
            'lost_pet_reports' => [
                [
                    'local_id' => 'lost-invalid',
                    'remote_id' => null,
                    'pet_local_uuid' => 'missing-pet',
                    'last_seen_latitude' => 3.4516,
                    'last_seen_longitude' => -76.5320,
                    'details' => 'Brown dog with blue collar',
                    'disappearance_date' => now()->subDay()->format('Y-m-d H:i:s'),
                    'photo_url' => '',
                    'phone' => '',
                    'sync_status' => 'synced',
                    'last_modified_at' => now()->format('Y-m-d H:i:s'),
                ],
            ],
        ], $headers);

        $response
            ->assertUnprocessable()
            ->assertJsonValidationErrors([
                'lost_pet_reports.0.phone',
            ]);
    }

    public function test_lost_pet_sync_accepts_null_photo_and_uses_pet_photo(): void
    {
        $user = User::factory()->create();
        $headers = $this->authHeaders($user);
        $pet = $this->postJson('/api/pets', [
            'local_id' => 'pet-local-photo',
            'local_uuid' => 'pet-local-photo',
            'name' => 'Luna',
            'photo_path' => 'https://example.com/luna.jpg',
        ], $headers)->json('data');

        $response = $this->postJson('/api/lost-pet-reports/sync', [
            'lost_pet_reports' => [[
                'local_id' => 'lost-null-photo',
                'remote_id' => null,
                'pet_local_uuid' => $pet['local_uuid'],
                'last_seen_latitude' => 3.4516,
                'last_seen_longitude' => -76.5320,
                'details' => 'Se perdio cerca del parque',
                'disappearance_date' => now()->subDay()->format('Y-m-d H:i:s'),
                'photo_url' => null,
                'phone' => '5551234',
                'sync_status' => 'created',
                'last_modified_at' => now()->format('Y-m-d H:i:s'),
            ]],
        ], $headers);

        $response
            ->assertOk()
            ->assertJsonPath('sync_results.synced', 1)
            ->assertJsonPath('sync_results.errors', 0);

        $this->assertDatabaseHas('lost_pet_reports', [
            'local_id' => 'lost-null-photo',
            'photo_url' => 'https://example.com/luna.jpg',
        ]);
        $this->assertDatabaseHas('pets', [
            'local_uuid' => 'pet-local-photo',
            'status' => 'perdida',
        ]);

        $this->getJson('/api/lost-pet-reports?include_archived=1', $headers)
            ->assertOk()
            ->assertJsonPath('data.0.pet.local_uuid', 'pet-local-photo')
            ->assertJsonPath('data.0.pet.status', 'perdida');
    }
}
