<?php

namespace App\Services\Auth;

use App\Models\ApiToken;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class AuthTokenService
{
    /**
     * @return array{plain_token: string}
     */
    public function issueToken(User $user, string $name): array
    {
        $plainToken = Str::random(64);

        ApiToken::create([
            'user_id' => $user->id,
            'name' => $name,
            'token_hash' => hash('sha256', $plainToken),
            'last_used_at' => now(),
        ]);

        return [
            'plain_token' => $plainToken,
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
}
