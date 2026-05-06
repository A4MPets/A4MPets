<?php

namespace Tests\Feature\Auth;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

/**
 * Pruebas de feature para inicio de sesión
 * Casos: F1-007, F1-008, F1-009
 */
class LoginTest extends TestCase
{
    use RefreshDatabase;

    /**
     * F1-007: Login exitoso con email retorna token de acceso y HTTP 200
     */
    public function test_login_with_email_returns_token_and_200(): void
    {
        $user = User::factory()->create([
            'email'    => 'qa.login@a4mpets.test',
            'password' => Hash::make('password_qa_123'),
        ]);

        $response = $this->postJson('/api/auth/login', [
            'login'    => 'qa.login@a4mpets.test',
            'password' => 'password_qa_123',
        ]);

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data' => ['user', 'access_token', 'token_type'],
            ])
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.token_type', 'Bearer');
    }

    /**
     * F1-008: Login exitoso con nombre de usuario retorna token de acceso
     */
    public function test_login_with_username_returns_token_and_200(): void
    {
        $user = User::factory()->create([
            'name'     => 'qa_username_test',
            'password' => Hash::make('password_qa_123'),
        ]);

        $response = $this->postJson('/api/auth/login', [
            'login'    => 'qa_username_test',
            'password' => 'password_qa_123',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.user.name', 'qa_username_test');
    }

    /**
     * F1-009: Login con credenciales inválidas retorna HTTP 422 con mensaje de error
     */
    public function test_login_with_wrong_credentials_returns_422(): void
    {
        $user = User::factory()->create([
            'email'    => 'real@a4mpets.test',
            'password' => Hash::make('correct_password'),
        ]);

        $response = $this->postJson('/api/auth/login', [
            'login'    => 'real@a4mpets.test',
            'password' => 'wrong_password',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['login']);
    }

    /**
     * F1-009 extra: Login con usuario inexistente retorna 422
     */
    public function test_login_with_nonexistent_user_returns_422(): void
    {
        $response = $this->postJson('/api/auth/login', [
            'login'    => 'noexiste@a4mpets.test',
            'password' => 'cualquier_pass',
        ]);

        $response->assertStatus(422);
    }

    /**
     * Verificación de logout: revoca el token y retorna 200
     */
    public function test_logout_revokes_token_and_returns_200(): void
    {
        $user = User::factory()->create([
            'password' => Hash::make('pass_qa_123'),
        ]);

        // Login para obtener token
        $loginResponse = $this->postJson('/api/auth/login', [
            'login'    => $user->email,
            'password' => 'pass_qa_123',
        ]);
        $token = $loginResponse->json('data.access_token');

        // Logout con el token
        $response = $this->withHeader('Authorization', 'Bearer ' . $token)
            ->postJson('/api/auth/logout');

        $response->assertStatus(200)
            ->assertJsonPath('success', true);
    }
}
