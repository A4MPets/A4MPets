<?php

namespace Tests\Feature\Media;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
use Tests\Concerns\CreatesApiToken;
use Tests\TestCase;

/**
 * Pruebas de feature para subida de imágenes en base64
 * Casos: F1-021, F1-022
 */
class MediaUploadTest extends TestCase
{
    use RefreshDatabase, CreatesApiToken;

    /**
     * F1-021: Upload de imagen en base64 válida retorna URL de acceso
     */
    public function test_upload_valid_base64_image_returns_url(): void
    {
        Storage::fake('local');

        $user = User::factory()->create();

        // Imagen PNG mínima válida en base64 (1x1 pixel transparente)
        $minPng = base64_encode(
            "\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc\x00\x01\x00\x00\x05\x00\x01\r\n-\xb4\x00\x00\x00\x00IEND\xaeB`\x82"
        );

        $response = $this->withHeaders($this->authHeaders($user))
            ->postJson('/api/media/upload', [
                'bucket'     => 'pets',
                'image_data' => 'data:image/png;base64,' . $minPng,
                'file_name'  => 'test_qa.png',
            ]);

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data' => ['url', 'bucket', 'file_name'],
            ])
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.bucket', 'pets');
    }

    /**
     * F1-022: Upload con image_data inválida (no es base64) retorna HTTP 422
     */
    public function test_upload_invalid_base64_returns_422(): void
    {
        $user = User::factory()->create();

        $response = $this->withHeaders($this->authHeaders($user))
            ->postJson('/api/media/upload', [
                'bucket'     => 'pets',
                'image_data' => 'esto_no_es_base64_valido!!!$$$',
            ]);

        $response->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    /**
     * F1-022 extra: Upload con bucket inválido retorna HTTP 422
     */
    public function test_upload_with_invalid_bucket_returns_422(): void
    {
        $user = User::factory()->create();

        $minPng = base64_encode('fake_image_data');

        $response = $this->withHeaders($this->authHeaders($user))
            ->postJson('/api/media/upload', [
                'bucket'     => 'invalid_bucket',
                'image_data' => 'data:image/png;base64,' . $minPng,
            ]);

        $response->assertStatus(422);
    }

    /**
     * F1-021 extra: La ruta POST /api/media/upload NO requiere autenticación por diseño
     * (línea 46 de api.php - sin middleware). El endpoint es público.
     * Enviando datos inválidos retorna 422 (error de validación).
     */
    public function test_upload_without_auth_accepts_request_since_route_is_public(): void
    {
        // La ruta /api/media/upload es pública (sin middleware de autenticación)
        // Envíamos datos inválidos, espera 422 de validación
        $response = $this->postJson('/api/media/upload', [
            'bucket'     => 'pets',
            'image_data' => 'not_valid_base64!!!',
        ]);

        // Sin auth OK (ruta pública), falla por datos inválidos -> 422
        $response->assertStatus(422);
    }
}
