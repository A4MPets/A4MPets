<?php

namespace Tests\Feature\Auth;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Pruebas de feature para registro de usuarios
 * Casos: F1-004, F1-005, F1-006
 */
class RegisterTest extends TestCase
{
    use RefreshDatabase;

    /**
     * F1-004: Registro exitoso retorna token, datos de usuario y HTTP 201
     */
    public function test_register_returns_token_and_user_data_on_success(): void
    {
        $response = $this->postJson('/api/auth/register', [
            'name'                  => 'qa_tester',
            'email'                 => 'qa@a4mpets.test',
            'password'              => 'secret1234',
            'password_confirmation' => 'secret1234',
        ]);

        $response->assertStatus(201)
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'user' => ['id', 'name', 'email'],
                    'access_token',
                    'token_type',
                ],
            ])
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.token_type', 'Bearer');

        // Verifica que el usuario fue creado en BD
        $this->assertDatabaseHas('users', ['email' => 'qa@a4mpets.test']);
    }

    /**
     * F1-005: Registro con email duplicado retorna HTTP 422 con error de validación
     */
    public function test_register_fails_with_duplicate_email(): void
    {
        User::factory()->create(['email' => 'duplicate@a4mpets.test']);

        $response = $this->postJson('/api/auth/register', [
            'name'                  => 'otro_usuario',
            'email'                 => 'duplicate@a4mpets.test',
            'password'              => 'secret1234',
            'password_confirmation' => 'secret1234',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['email']);
    }

    /**
     * F1-006: Registro con contraseña muy corta retorna HTTP 422 con error de validación
     */
    public function test_register_fails_when_password_too_short(): void
    {
        $response = $this->postJson('/api/auth/register', [
            'name'                  => 'qa_short_pass',
            'email'                 => 'short@a4mpets.test',
            'password'              => '123',
            'password_confirmation' => '123',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['password']);
    }

    /**
     * F1-006 extra: Registro con confirmación de contraseña incorrecta retorna error de validación
     */
    public function test_register_fails_when_passwords_dont_match(): void
    {
        $response = $this->postJson('/api/auth/register', [
            'name'                  => 'qa_mismatch',
            'email'                 => 'mismatch@a4mpets.test',
            'password'              => 'secret1234',
            'password_confirmation' => 'diferente5678',
        ]);

        $response->assertStatus(422)
            ->assertJsonValidationErrors(['password']);
    }
}
