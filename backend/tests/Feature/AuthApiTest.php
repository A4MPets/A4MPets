<?php

namespace Tests\Feature;

use App\Models\ApiToken;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_register_login_profile_and_logout_flow(): void
    {
        $registerResponse = $this->postJson('/api/auth/register', [
            'name' => 'Nestor',
            'email' => 'nestor@example.com',
            'password' => 'secret123',
            'password_confirmation' => 'secret123',
        ]);

        $registerResponse
            ->assertCreated()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.user.email', 'nestor@example.com');

        $token = $registerResponse->json('data.access_token');
        $headers = ['Authorization' => 'Bearer '.$token];

        $this->getJson('/api/auth/me', $headers)
            ->assertOk()
            ->assertJsonPath('data.email', 'nestor@example.com');

        $this->putJson('/api/auth/profile', [
            'name' => 'Nestor Updated',
            'profile_photo_url' => 'https://example.com/avatar.png',
        ], $headers)
            ->assertOk()
            ->assertJsonPath('data.user.name', 'Nestor Updated')
            ->assertJsonPath('data.user.profile_photo_url', 'https://example.com/avatar.png');

        $this->postJson('/api/auth/logout', [], $headers)
            ->assertOk()
            ->assertJsonPath('success', true);

        $this->assertDatabaseCount('api_tokens', 0);

        $loginResponse = $this->postJson('/api/auth/login', [
            'login' => 'nestor@example.com',
            'password' => 'secret123',
        ]);

        $loginResponse
            ->assertOk()
            ->assertJsonPath('data.user.name', 'Nestor Updated');

        $this->assertDatabaseCount('api_tokens', 1);
        $this->assertInstanceOf(ApiToken::class, ApiToken::query()->first());
    }
}
