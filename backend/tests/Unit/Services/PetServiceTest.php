<?php

namespace Tests\Unit\Services;

use App\Models\LostPetReport;
use App\Models\Pet;
use App\Models\User;
use App\Services\Pets\PetService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Pruebas unitarias para PetService
 * Casos: F1-010, F1-011, F1-012, F1-013
 */
class PetServiceTest extends TestCase
{
    use RefreshDatabase;

    private PetService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = new PetService();
    }

    /**
     * F1-010: store crea mascota con todos los campos obligatorios y opcionales
     */
    public function test_store_creates_pet_with_all_fields(): void
    {
        $user = User::factory()->create();

        $pet = $this->service->store($user->id, [
            'name'          => 'Luna QA',
            'birth_date'    => '2024-01-15',
            'adoption_date' => '2024-05-20',
            'status'        => 'normal',
            'is_ownerless'  => false,
        ]);

        $this->assertInstanceOf(Pet::class, $pet);
        $this->assertEquals('Luna QA', $pet->name);
        $this->assertEquals('normal', $pet->status);
        $this->assertEquals($user->id, $pet->user_id);
        $this->assertFalse((bool) $pet->is_ownerless);

        // Verifica persistencia en base de datos
        $this->assertDatabaseHas('pets', [
            'id'   => $pet->id,
            'name' => 'Luna QA',
        ]);
    }

    /**
     * F1-011: normalizePetStatus convierte 'lost' y 'perdida' al valor estándar 'perdida'
     */
    public function test_store_normalizes_lost_status_to_perdida(): void
    {
        $user = User::factory()->create();

        $petWithLost = $this->service->store($user->id, ['name' => 'P1', 'status' => 'lost']);
        $this->assertEquals('perdida', $petWithLost->status);
    }

    public function test_store_normalizes_perdida_status_stays_perdida(): void
    {
        $user = User::factory()->create();

        $petWithPerdida = $this->service->store($user->id, ['name' => 'P2', 'status' => 'perdida']);
        $this->assertEquals('perdida', $petWithPerdida->status);
    }

    public function test_store_keeps_normal_status_unchanged(): void
    {
        $user = User::factory()->create();

        $petNormal = $this->service->store($user->id, ['name' => 'P3', 'status' => 'normal']);
        $this->assertEquals('normal', $petNormal->status);
    }

    /**
     * F1-012: canMutate retorna false para no propietario y true para propietario
     */
    public function test_can_mutate_returns_false_for_different_user(): void
    {
        $userA = User::factory()->create();
        $userB = User::factory()->create();

        $pet = Pet::factory()->create(['user_id' => $userA->id]);

        $this->assertFalse($this->service->canMutate($userB->id, $pet));
    }

    public function test_can_mutate_returns_true_for_owner(): void
    {
        $user = User::factory()->create();
        $pet  = Pet::factory()->create(['user_id' => $user->id]);

        $this->assertTrue($this->service->canMutate($user->id, $pet));
    }

    public function test_can_mutate_returns_false_for_null_user(): void
    {
        $pet = Pet::factory()->create();

        $this->assertFalse($this->service->canMutate(null, $pet));
    }

    /**
     * F1-013: markFound cambia status a 'normal' y elimina reportes de mascota perdida asociados
     */
    public function test_mark_found_changes_status_to_normal_and_removes_lost_reports(): void
    {
        $user = User::factory()->create();

        $pet = Pet::factory()->create([
            'user_id' => $user->id,
            'status'  => 'perdida',
        ]);

        // Crear reporte de mascota perdida asociado
        LostPetReport::factory()->create([
            'user_id' => $user->id,
            'pet_id'  => $pet->id,
        ]);

        $this->assertDatabaseHas('lost_pet_reports', ['pet_id' => $pet->id]);

        $result = $this->service->markFound($pet);

        $this->assertEquals('normal', $result->status);
        $this->assertDatabaseMissing('lost_pet_reports', ['pet_id' => $pet->id]);
    }
}
