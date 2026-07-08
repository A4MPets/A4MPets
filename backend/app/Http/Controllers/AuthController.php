<?php

namespace App\Http\Controllers;

use App\Http\Requests\Auth\DeleteAccountRequest;
use App\Http\Requests\Auth\LoginRequest;
use App\Http\Requests\Auth\RegisterRequest;
use App\Http\Requests\Auth\UpdateProfileRequest;
use App\Models\User;
use App\Services\Auth\AccountDeletionService;
use App\Services\Auth\AuthTokenService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function __construct(
        private readonly AuthTokenService $authTokenService,
        private readonly AccountDeletionService $accountDeletionService
    ) {}

    public function register(RegisterRequest $request): JsonResponse
    {
        $validated = $request->validated();

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => $validated['password'],
        ]);

        $token = $this->authTokenService->issueToken($user, 'mobile-register');

        return response()->json([
            'success' => true,
            'message' => 'Usuario registrado exitosamente',
            'data' => [
                'user' => $this->authTokenService->formatUser($user),
                'access_token' => $token['plain_token'],
                'token_type' => 'Bearer',
                'expires_at' => $token['expires_at']->toISOString(),
            ],
        ], 201);
    }

    public function login(LoginRequest $request): JsonResponse
    {
        $validated = $request->validated();
        $login = $validated['login'];

        $user = User::query()
            ->where('email', $login)
            ->orWhere('name', $login)
            ->first();

        if (! $user || ! Hash::check($validated['password'], $user->password)) {
            throw ValidationException::withMessages([
                'login' => ['Las credenciales proporcionadas no son validas.'],
            ]);
        }

        $token = $this->authTokenService->issueToken($user, 'mobile-login');

        return response()->json([
            'success' => true,
            'message' => 'Sesion iniciada correctamente',
            'data' => [
                'user' => $this->authTokenService->formatUser($user),
                'access_token' => $token['plain_token'],
                'token_type' => 'Bearer',
                'expires_at' => $token['expires_at']->toISOString(),
            ],
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        $user = $request->user();

        if (! $user) {
            return response()->json([
                'success' => false,
                'message' => 'No autenticado',
            ], 401);
        }

        return response()->json([
            'success' => true,
            'data' => $this->authTokenService->formatUser($user),
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $this->authTokenService->revokeCurrentToken($request);

        return response()->json([
            'success' => true,
            'message' => 'Sesion cerrada correctamente',
        ]);
    }

    public function deleteAccount(DeleteAccountRequest $request): JsonResponse
    {
        $user = $request->user();
        $validated = $request->validated();

        if (! $user || ! Hash::check($validated['password'], $user->password)) {
            throw ValidationException::withMessages([
                'password' => ['La contrasena no es valida.'],
            ]);
        }

        $this->accountDeletionService->deleteAccount($user);

        return response()->json([
            'success' => true,
            'message' => 'Cuenta eliminada correctamente',
        ]);
    }

    public function updateProfile(UpdateProfileRequest $request): JsonResponse
    {
        $user = $request->user();

        if (! $user) {
            return response()->json([
                'success' => false,
                'message' => 'No autenticado',
            ], 401);
        }

        $validated = $request->validated();

        $user->fill([
            'name' => $validated['name'] ?? $user->name,
            'profile_photo_url' => $validated['profile_photo_url'] ?? null,
        ]);
        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'Perfil actualizado correctamente',
            'data' => [
                'user' => $this->authTokenService->formatUser($user),
            ],
        ]);
    }
}
