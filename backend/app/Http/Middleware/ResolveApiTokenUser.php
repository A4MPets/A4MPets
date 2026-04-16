<?php

namespace App\Http\Middleware;

use App\Models\ApiToken;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

class ResolveApiTokenUser
{
    public function handle(Request $request, Closure $next): Response
    {
        $bearerToken = $request->bearerToken();

        if ($bearerToken) {
            $tokenHash = hash('sha256', $bearerToken);
            $apiToken = ApiToken::with('user')
                ->where('token_hash', $tokenHash)
                ->first();

            if ($apiToken && ($apiToken->expires_at === null || $apiToken->expires_at->isFuture())) {
                $apiToken->forceFill([
                    'last_used_at' => now(),
                ])->save();

                $user = $apiToken->user;
                if ($user) {
                    Auth::setUser($user);
                    $request->setUserResolver(static fn () => $user);
                    $request->attributes->set('api_token_model', $apiToken);
                }
            }
        }

        return $next($request);
    }
}
