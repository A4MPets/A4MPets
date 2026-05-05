<?php

namespace Tests\Feature;

use App\Models\Pet;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\CreatesApiToken;
use Tests\TestCase;

class PetApiTest extends TestCase
{
    use CreatesApiToken;
    use RefreshDatabase;

    public function test_pet_crud_flow(): void
    {
        $user = User::factory()->create();
        $headers = $this->authHeaders($user);

        $storeResponse = $this->postJson('/api/pets', [
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

        $this->deleteJson('/api/pets/'.$petId, [], $headers)
            ->assertOk()
            ->assertJsonPath('success', true);
    }

    public function test_owned_pet_scope_requires_token_and_excludes_ownerless_and_other_users(): void
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();

        $ownedPet = Pet::create([
            'user_id' => $user->id,
            'name' => 'Milo',
            'registered_at' => now(),
            'status' => 'normal',
            'is_ownerless' => false,
        ]);

        Pet::create([
            'user_id' => $otherUser->id,
            'name' => 'Other',
            'registered_at' => now(),
            'status' => 'normal',
            'is_ownerless' => false,
        ]);

        Pet::create([
            'user_id' => null,
            'name' => null,
            'registered_at' => now(),
            'status' => 'normal',
            'is_ownerless' => true,
        ]);

        $this->getJson('/api/pets')
            ->assertOk()
            ->assertJsonCount(3, 'data');

        $this->getJson('/api/pets?scope=mine')
            ->assertUnauthorized();

        $response = $this->getJson('/api/pets?scope=mine', $this->authHeaders($user));

        $response
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $ownedPet->id)
            ->assertJsonPath('data.0.is_ownerless', false);
    }
}
