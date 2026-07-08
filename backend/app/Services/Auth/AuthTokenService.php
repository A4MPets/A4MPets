<?php

namespace App\Services\Auth;

use App\Models\ApiToken;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class AuthTokenService
{
    private const DEFAULT_TOKEN_LIFETIME_MINUTES = 43200;

    /**
     * @return array{plain_token: string, expires_at: \Illuminate\Support\Carbon}
     */
    public function issueToken(User $user, string $name): array
    {
        $plainToken = Str::random(64);
        $expiresAt = now()->addMinutes($this->tokenLifetimeMinutes());

        ApiToken::create([
            'user_id' => $user->id,
            'name' => $name,
            'token_hash' => hash('sha256', $plainToken),
            'last_used_at' => now(),
            'expires_at' => $expiresAt,
        ]);

        return [
            'plain_token' => $plainToken,
            'expires_at' => $expiresAt,
        ];
    }

    public function revokeCurrentToken(Request $request): void
    {
        $apiToken = $request->attributes->get('api_token_model');

        if ($apiToken instanceof ApiToken) {
            $apiToken->delete();
        }
    }

    /**
     * @return array<string, mixed>
     */
    public function formatUser(User $user): array
    {
        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'profile_photo_url' => $user->profile_photo_url,
        ];
    }

    private function tokenLifetimeMinutes(): int
    {
        $configured = (int) config('auth.api_token_lifetime_minutes', self::DEFAULT_TOKEN_LIFETIME_MINUTES);

        return $configured > 0 ? $configured : self::DEFAULT_TOKEN_LIFETIME_MINUTES;
    }
}
