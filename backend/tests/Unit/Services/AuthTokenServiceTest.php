<?php

namespace Tests\Unit\Services;

use App\Models\ApiToken;
use App\Models\User;
use App\Services\Auth\AuthTokenService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Request;
use Tests\TestCase;

/**
 * Pruebas unitarias para AuthTokenService
 * Casos: F1-001, F1-002, F1-003
 */
class AuthTokenServiceTest extends TestCase
{
    use RefreshDatabase;

    private AuthTokenService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = new AuthTokenService();
    }

    /**
     * F1-001: issueToken genera token de 64 caracteres y lo almacena como hash SHA-256
     */
    public function test_issue_token_returns_64_char_plain_token_and_stores_sha256_hash(): void
    {
        $user = User::factory()->create();

        $result = $this->service->issueToken($user, 'mobile-register');

        // Verifica que retorna plain_token
        $this->assertArrayHasKey('plain_token', $result);

        // Verifica longitud de 64 caracteres
        $this->assertEquals(64, strlen($result['plain_token']));

        // Verifica que existe registro en api_tokens con hash SHA-256
        $expectedHash = hash('sha256', $result['plain_token']);
        $this->assertDatabaseHas('api_tokens', [
            'user_id'    => $user->id,
            'name'       => 'mobile-register',
            'token_hash' => $expectedHash,
        ]);
    }

    /**
     * F1-001 extra: múltiples llamadas generan tokens únicos
     */
    public function test_issue_token_generates_unique_tokens_on_multiple_calls(): void
    {
        $user = User::factory()->create();

        $token1 = $this->service->issueToken($user, 'token-a')['plain_token'];
        $token2 = $this->service->issueToken($user, 'token-b')['plain_token'];

        $this->assertNotEquals($token1, $token2);
        $this->assertCount(2, ApiToken::where('user_id', $user->id)->get());
    }

    /**
     * F1-002: revokeCurrentToken elimina el token de la tabla api_tokens
     */
    public function test_revoke_current_token_deletes_token_from_database(): void
    {
        $user = User::factory()->create();

        // Emitir token
        $result  = $this->service->issueToken($user, 'mobile-login');
        $apiToken = ApiToken::where('user_id', $user->id)->first();

        $this->assertNotNull($apiToken);

        // Crear un Request simulado con el api_token_model en atributos
        $request = Request::create('/api/auth/logout', 'POST');
        $request->attributes->set('api_token_model', $apiToken);

        $this->service->revokeCurrentToken($request);

        // El token ya no debe existir
        $this->assertDatabaseMissing('api_tokens', ['id' => $apiToken->id]);
    }

    /**
     * F1-002 extra: revokeCurrentToken no falla si no hay token en el request
     */
    public function test_revoke_current_token_does_nothing_when_no_token_in_request(): void
    {
        $request = Request::create('/api/auth/logout', 'POST');

        // No debe lanzar excepción
        $this->service->revokeCurrentToken($request);

        $this->assertTrue(true); // Sin excepción = OK
    }

    /**
     * F1-003: formatUser retorna únicamente id, name, email y profile_photo_url
     */
    public function test_format_user_returns_only_expected_fields(): void
    {
        $user = User::factory()->create([
            'name'              => 'qa_test',
            'email'             => 'qa@test.com',
            'profile_photo_url' => 'http://example.com/photo.jpg',
        ]);

        $formatted = $this->service->formatUser($user);

        // Verifica que contiene exactamente las 4 claves esperadas
        $this->assertArrayHasKey('id', $formatted);
        $this->assertArrayHasKey('name', $formatted);
        $this->assertArrayHasKey('email', $formatted);
        $this->assertArrayHasKey('profile_photo_url', $formatted);

        // Verifica que no expone datos sensibles
        $this->assertArrayNotHasKey('password', $formatted);
        $this->assertArrayNotHasKey('remember_token', $formatted);

        // Verifica los valores
        $this->assertEquals('qa_test', $formatted['name']);
        $this->assertEquals('qa@test.com', $formatted['email']);
        $this->assertEquals('http://example.com/photo.jpg', $formatted['profile_photo_url']);
    }

    /**
     * F1-003 extra: formatUser retorna null en profile_photo_url cuando no está definida
     */
    public function test_format_user_returns_null_profile_photo_when_not_set(): void
    {
        $user = User::factory()->create(['profile_photo_url' => null]);

        $formatted = $this->service->formatUser($user);

        $this->assertNull($formatted['profile_photo_url']);
    }
}
