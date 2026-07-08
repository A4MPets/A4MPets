<?php

namespace App\Http\Middleware;

use App\Models\ApiToken;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Symfony\Component\HttpFoundation\Response;

class ResolveApiTokenUser
{
    public function handle(Request $request, Closure $next, string $mode = 'optional'): Response
    {
        Auth::forgetGuards();
        $request->setUserResolver(static fn () => null);

        $bearerToken = $request->bearerToken();

        if ($bearerToken) {
            $tokenHash = hash('sha256', $bearerToken);
            $apiToken = ApiToken::with('user')
                ->where('token_hash', $tokenHash)
                ->first();

            if ($apiToken && $apiToken->expires_at?->isFuture()) {
                $apiToken->forceFill([
                    'last_used_at' => now(),
                ])->save();

                $user = $apiToken->user;
                if ($user) {
                    Auth::setUser($user);
                    $request->setUserResolver(static fn () => $user);
                    $request->attributes->set('api_token_model', $apiToken);
                }
            } elseif ($apiToken) {
                $apiToken->delete();
            }
        }

        if ($mode === 'required' && ! $request->user()) {
            return response()->json([
                'success' => false,
                'message' => 'No autenticado',
            ], 401);
        }

        return $next($request);
    }
}
