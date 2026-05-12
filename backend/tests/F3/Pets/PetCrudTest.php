<?php

namespace Tests\F3\Pets;

use App\Models\LostPetReport;
use App\Models\Pet;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\CreatesApiToken;
use Tests\TestCase;

/**
 * Pruebas de feature para CRUD de mascotas
 * Casos: F3-014, F3-015
 */
class PetCrudTest extends TestCase
{
    use RefreshDatabase, CreatesApiToken;

    /**
     * F3-014: Crear mascota con token válido retorna HTTP 201 y datos de la mascota
     */
    public function test_create_pet_with_valid_token_returns_201(): void
    {
        $user = User::factory()->create();

        $response = $this->withHeaders($this->authHeaders($user))
            ->postJson('/api/pets', [
                'name'         => 'Firulais QA',
                'status'       => 'normal',
                'is_ownerless' => false,
                'total_walks'  => 5,
            ]);

        $response->assertStatus(201)
            ->assertJsonStructure([
                'success',
                'data' => ['id', 'name', 'status'],
            ])
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.name', 'Firulais QA');

        $this->assertDatabaseHas('pets', [
            'name'    => 'Firulais QA',
            'user_id' => $user->id,
        ]);
    }

    /**
     * F3-014 extra: POST /api/pets rechaza solicitudes sin token.
     */
    public function test_create_pet_without_token_returns_401(): void
    {
        $response = $this->postJson('/api/pets', [
            'name'   => 'Pet sin token',
            'status' => 'normal',
        ]);

        $response->assertStatus(401)
            ->assertJsonPath('success', false)
            ->assertJsonPath('message', 'No autenticado');

        $this->assertDatabaseMissing('pets', [
            'name' => 'Pet sin token',
        ]);
    }

    /**
     * F3-015: Intentar modificar mascota de otro usuario retorna HTTP 403
     */
    public function test_update_pet_of_other_user_returns_403(): void
    {
        $owner  = User::factory()->create();
        $attacker = User::factory()->create();

        $pet = Pet::factory()->create(['user_id' => $owner->id]);

        $response = $this->withHeaders($this->authHeaders($attacker))
            ->putJson("/api/pets/{$pet->id}", [
                'name'   => 'Intentando robar mascota',
                'status' => 'normal',
            ]);

        $response->assertStatus(403);
    }

    /**
     * F3-015 extra: Propietario puede actualizar su propia mascota
     */
    public function test_owner_can_update_own_pet(): void
    {
        $user = User::factory()->create();
        $pet  = Pet::factory()->create(['user_id' => $user->id, 'name' => 'Original']);

        $response = $this->withHeaders($this->authHeaders($user))
            ->putJson("/api/pets/{$pet->id}", [
                'name'   => 'Actualizado QA',
                'status' => 'normal',
            ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.name', 'Actualizado QA');
    }

    /**
     * F3-015 extra: Propietario puede eliminar su propia mascota
     */
    public function test_owner_can_delete_own_pet(): void
    {
        $user = User::factory()->create();
        $pet  = Pet::factory()->create(['user_id' => $user->id]);

        $response = $this->withHeaders($this->authHeaders($user))
            ->deleteJson("/api/pets/{$pet->id}");

        $response->assertStatus(200);
        $this->assertDatabaseMissing('pets', ['id' => $pet->id]);
    }

    public function test_owner_can_list_mine_and_show_pet(): void
    {
        $user = User::factory()->create();
        $other = User::factory()->create();
        $pet = Pet::factory()->create([
            'user_id' => $user->id,
            'name' => 'Mascota propia F3',
            'is_ownerless' => false,
        ]);
        Pet::factory()->create(['user_id' => $other->id, 'name' => 'Mascota ajena F3']);
        Pet::factory()->ownerless()->create(['name' => 'Mascota invitada F3']);

        $this->getJson('/api/pets?scope=mine')
            ->assertStatus(401);

        $this->withHeaders($this->authHeaders($user))
            ->getJson('/api/pets?scope=mine&per_page=10')
            ->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $pet->id);

        $this->getJson("/api/pets/{$pet->id}")
            ->assertStatus(200)
            ->assertJsonPath('data.name', 'Mascota propia F3');
    }

    public function test_owner_can_mark_pet_found_and_non_owner_is_rejected(): void
    {
        $owner = User::factory()->create();
        $other = User::factory()->create();
        $pet = Pet::factory()->lost()->create(['user_id' => $owner->id]);

        LostPetReport::factory()->create([
            'user_id' => $owner->id,
            'pet_id' => $pet->id,
        ]);

        $this->withHeaders($this->authHeaders($other))
            ->postJson("/api/pets/{$pet->id}/mark-found")
            ->assertStatus(403);

        $this->withHeaders($this->authHeaders($owner))
            ->postJson("/api/pets/{$pet->id}/mark-found")
            ->assertStatus(200)
            ->assertJsonPath('data.status', 'normal');

        $this->assertDatabaseMissing('lost_pet_reports', ['pet_id' => $pet->id]);
    }

    public function test_pet_api_side_effects_keep_owner_relationships_consistent(): void
    {
        $owner = User::factory()->create();

        $create = $this->withHeaders($this->authHeaders($owner))
            ->postJson('/api/pets', [
                'name' => 'Mascota relaciones F3',
                'status' => 'lost',
                'is_ownerless' => false,
            ]);

        $create->assertStatus(201);
        $pet = Pet::query()->findOrFail($create->json('data.id'));
        LostPetReport::factory()->create([
            'user_id' => $owner->id,
            'pet_id' => $pet->id,
        ]);

        $this->assertTrue($pet->user()->is($owner));
        $this->assertSame(1, $owner->pets()->whereKey($pet->id)->count());
        $this->assertSame(1, $owner->apiTokens()->count());
        $this->assertSame(1, $pet->lostPetReports()->count());
        $this->assertSame(0, $pet->foundPetReports()->count());
    }
}
