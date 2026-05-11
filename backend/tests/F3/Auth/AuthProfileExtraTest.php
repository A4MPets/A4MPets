<?php

namespace Tests\F3\Auth;

use App\Models\ApiToken;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Auth;
use Tests\Concerns\CreatesApiToken;
use Tests\TestCase;

/**
 * F3-003/F3-009-extra: Auth profile, me, and logout controller coverage.
 */
class AuthProfileExtraTest extends TestCase
{
    use RefreshDatabase, CreatesApiToken;

    public function test_me_and_profile_update_require_or_use_resolved_api_token_user(): void
    {
        $user = User::factory()->create(['name' => 'Before']);

        $this->getJson('/api/auth/me')
            ->assertStatus(401)
            ->assertJsonPath('success', false);

        $headers = $this->authHeaders($user);

        $this->withHeaders($headers)
            ->getJson('/api/auth/me')
            ->assertStatus(200)
            ->assertJsonPath('data.name', 'Before');

        $this->withHeaders($headers)
            ->putJson('/api/auth/profile', [
                'name' => 'After',
                'profile_photo_url' => 'profiles/after.png',
            ])
            ->assertStatus(200)
            ->assertJsonPath('data.user.name', 'After')
            ->assertJsonPath('data.user.profile_photo_url', 'profiles/after.png');
    }

    public function test_logout_revokes_current_token_and_invalid_token_is_ignored_by_middleware(): void
    {
        $user = User::factory()->create();
        $headers = $this->authHeaders($user);

        $this->withHeaders($headers)
            ->postJson('/api/auth/logout')
            ->assertStatus(200)
            ->assertJsonPath('success', true);

        $this->assertSame(0, ApiToken::count());

        Auth::forgetGuards();

        $this->withHeaders(['Authorization' => 'Bearer invalid-token'])
            ->getJson('/api/auth/me')
            ->assertStatus(401);
    }
}
