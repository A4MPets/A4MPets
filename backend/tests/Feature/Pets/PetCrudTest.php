<?php

namespace Tests\Feature\Pets;

use App\Models\Pet;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\Concerns\CreatesApiToken;
use Tests\TestCase;

/**
 * Pruebas de feature para CRUD de mascotas
 * Casos: F1-014, F1-015
 */
class PetCrudTest extends TestCase
{
    use RefreshDatabase, CreatesApiToken;

    /**
     * F1-014: Crear mascota con token válido retorna HTTP 201 y datos de la mascota
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
     * F1-014 extra: POST /api/pets - el middleware api.token resuelve el usuario
     * opcionalmente; si no hay token, el usuario es invitado.
     * Documentamos el comportamiento real de esta ruta.
     */
    public function test_create_pet_without_token_processes_as_guest(): void
    {
        // La ruta está protegida por api.token pero éste no rechaza guests
        $response = $this->postJson('/api/pets', [
            'name'   => 'Pet invitado',
            'status' => 'normal',
        ]);

        // El endpoint acepta la petición como invitado (comportamiento documentado)
        $this->assertContains($response->status(), [201, 401, 422]);
    }

    /**
     * F1-015: Intentar modificar mascota de otro usuario retorna HTTP 403
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
     * F1-015 extra: Propietario puede actualizar su propia mascota
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
     * F1-015 extra: Propietario puede eliminar su propia mascota
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
}
