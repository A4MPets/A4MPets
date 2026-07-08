<?php

namespace Tests\F3\Auth;

use App\Models\ApiToken;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Str;
use Tests\Concerns\CreatesApiToken;
use Tests\TestCase;

/**
 * F3-003/F3-009-extra: Auth profile, me, and logout controller coverage.
 */
class AuthProfileExtraTest extends TestCase
{
    use CreatesApiToken, RefreshDatabase;

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

    public function test_expired_or_legacy_token_without_expiration_is_rejected(): void
    {
        $user = User::factory()->create();

        $expiredPlainToken = Str::random(64);
        ApiToken::create([
            'user_id' => $user->id,
            'name' => 'expired-token',
            'token_hash' => hash('sha256', $expiredPlainToken),
            'last_used_at' => now()->subDays(31),
            'expires_at' => now()->subMinute(),
        ]);

        $this->withHeaders(['Authorization' => 'Bearer '.$expiredPlainToken])
            ->getJson('/api/auth/me')
            ->assertStatus(401);

        $this->assertDatabaseMissing('api_tokens', [
            'token_hash' => hash('sha256', $expiredPlainToken),
        ]);

        $legacyPlainToken = Str::random(64);
        ApiToken::create([
            'user_id' => $user->id,
            'name' => 'legacy-token',
            'token_hash' => hash('sha256', $legacyPlainToken),
            'last_used_at' => now(),
            'expires_at' => null,
        ]);

        $this->withHeaders(['Authorization' => 'Bearer '.$legacyPlainToken])
            ->getJson('/api/auth/me')
            ->assertStatus(401);

        $this->assertDatabaseMissing('api_tokens', [
            'token_hash' => hash('sha256', $legacyPlainToken),
        ]);
    }
}
