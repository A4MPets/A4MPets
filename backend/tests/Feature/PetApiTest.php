<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\CreatesApiToken;
use Tests\TestCase;

class PetApiTest extends TestCase
{
    use CreatesApiToken;
    use RefreshDatabase;

    public function test_pet_crud_and_sync_flow(): void
    {
        $user = User::factory()->create();
        $headers = $this->authHeaders($user);

        $storeResponse = $this->postJson('/api/pets', [
            'local_id' => 'pet-local-1',
            'name' => 'Luna',
            'photo_path' => '/tmp/luna.png',
        ], $headers);

        $petId = $storeResponse->json('data.id');

        $storeResponse
            ->assertCreated()
            ->assertJsonPath('data.name', 'Luna');

        $this->getJson('/api/pets', $headers)
            ->assertOk()
            ->assertJsonCount(1, 'data');

        $this->putJson('/api/pets/'.$petId, [
            'name' => 'Luna Updated',
            'photo_path' => '/tmp/luna-2.png',
        ], $headers)
            ->assertOk()
            ->assertJsonPath('data.name', 'Luna Updated');

        $this->postJson('/api/pets/sync', [
            'pets' => [
                [
                    'local_id' => 'pet-local-1',
                    'remote_id' => (string) $petId,
                    'name' => 'Luna Synced',
                    'photo_path' => '/tmp/luna-sync.png',
                    'sync_status' => 'synced',
                    'last_modified_at' => now()->format('Y-m-d H:i:s'),
                ],
            ],
        ], $headers)
            ->assertOk()
            ->assertJsonPath('sync_results.synced', 1);

        $this->deleteJson('/api/pets/'.$petId, [], $headers)
            ->assertOk()
            ->assertJsonPath('success', true);
    }
}
