<?php

namespace Tests\Concerns;

use App\Models\ApiToken;
use App\Models\User;
use Illuminate\Support\Str;

trait CreatesApiToken
{
    /**
     * @return array{Authorization: string}
     */
    protected function authHeaders(User $user): array
    {
        $plainToken = Str::random(64);

        ApiToken::create([
            'user_id' => $user->id,
            'name' => 'test-token',
            'token_hash' => hash('sha256', $plainToken),
            'last_used_at' => now(),
        ]);

        return [
            'Authorization' => 'Bearer '.$plainToken,
        ];
    }
}
