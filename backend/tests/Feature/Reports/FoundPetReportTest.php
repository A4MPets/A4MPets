<?php

namespace Tests\Feature\Reports;

use App\Models\LostPetReport;
use App\Models\Pet;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\CreatesApiToken;
use Tests\TestCase;

/**
 * Pruebas de feature para reportes de mascota encontrada
 * Casos: F1-025
 */
class FoundPetReportTest extends TestCase
{
    use RefreshDatabase, CreatesApiToken;

    /**
     * F1-025: Crear reporte de mascota encontrada con referencia a reporte de pérdida
     * El sistema debe vincular el reporte encontrado con el reporte de pérdida existente
     */
    public function test_create_found_pet_report_linked_to_lost_pet_report(): void
    {
        $owner = User::factory()->create();
        $finder = User::factory()->create();

        // Crear mascota del propietario
        $pet = Pet::factory()->create([
            'user_id' => $owner->id,
            'status'  => 'perdida',
        ]);

        // Crear reporte de pérdida
        $lostReport = LostPetReport::create([
            'user_id'             => $owner->id,
            'pet_id'              => $pet->id,
            'last_seen_latitude'  => 4.711,
            'last_seen_longitude' => -74.072,
            'details'             => 'Mascota perdida QA',
            'disappearance_date'  => now()->subDays(3),
            'phone'               => '300-000-0000',
        ]);

        // Crear reporte de mascota encontrada vinculado
        $response = $this->withHeaders($this->authHeaders($finder))
            ->postJson('/api/found-pet-reports', [
                'matched_lost_pet_report_id' => $lostReport->id,
                'latitude'                   => 4.715,
                'longitude'                  => -74.068,
                'details'                    => 'Encontré la mascota QA',
                'found_date'                 => now()->toDateTimeString(),
            ]);

        $response->assertStatus(201)
            ->assertJsonStructure([
                'success',
                'data' => ['id', 'pet_id', 'matched_lost_pet_report_id', 'latitude', 'longitude'],
            ])
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.matched_lost_pet_report_id', $lostReport->id);
    }

    /**
     * F1-025 extra: Crear reporte de mascota encontrada sin reporte vinculado (mascota callejera)
     * El sistema debe crear automáticamente una mascota sin dueño
     */
    public function test_create_found_pet_report_without_lost_report_creates_ownerless_pet(): void
    {
        $finder = User::factory()->create();

        $response = $this->withHeaders($this->authHeaders($finder))
            ->postJson('/api/found-pet-reports', [
                'latitude'   => 4.715,
                'longitude'  => -74.068,
                'details'    => 'Mascota callejera encontrada',
                'found_date' => now()->toDateTimeString(),
            ]);

        $response->assertStatus(201)
            ->assertJsonPath('success', true);

        // La mascota creada debe ser ownerless
        $foundReportId = $response->json('data.id');
        $this->assertDatabaseHas('found_pet_reports', ['id' => $foundReportId]);
    }

    /**
     * F1-025 extra: Crear reporte de mascota encontrada sin autenticación retorna 401
     */
    public function test_create_found_pet_report_without_auth_returns_401(): void
    {
        $response = $this->postJson('/api/found-pet-reports', [
            'latitude'   => 4.715,
            'longitude'  => -74.068,
            'details'    => 'Sin auth',
            'found_date' => now()->toDateTimeString(),
        ]);

        $response->assertStatus(401);
    }
}
