<?php

namespace App\Http\Controllers;

use App\Http\Requests\Pets\StorePetRequest;
use App\Http\Requests\Pets\UpdatePetRequest;
use App\Models\Pet;
use App\Services\Pets\PetService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PetController extends Controller
{
    public function __construct(
        private readonly PetService $petService
    ) {}

    public function index(Request $request): JsonResponse
    {
        $scope = $request->query('scope');
        if ($scope === 'mine' && ! $request->user()) {
            return response()->json([
                'success' => false,
                'message' => 'No autenticado',
            ], 401);
        }

        $pets = $scope === 'mine'
            ? $this->petService->paginateOwnedForUser(
                (int) $request->user()->id,
                min((int) $request->query('per_page', 50), 100),
                (int) $request->query('page', 1)
            )
            : $this->petService->paginateForUser(
                $request->user()?->id,
                (bool) $request->query('include_archived'),
                min((int) $request->query('per_page', 50), 100),
                (int) $request->query('page', 1)
            );

        return response()->json([
            'success' => true,
            'data' => $pets->items(),
            'pagination' => [
                'total' => $pets->total(),
                'per_page' => $pets->perPage(),
                'current_page' => $pets->currentPage(),
                'last_page' => $pets->lastPage(),
            ],
        ]);
    }

    public function show(Pet $pet): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data' => $pet,
        ]);
    }

    public function store(StorePetRequest $request): JsonResponse
    {
        $pet = $this->petService->store(
            $request->user()?->id,
            $request->validated()
        );

        return response()->json([
            'success' => true,
            'data' => $pet,
        ], 201);
    }

    public function update(UpdatePetRequest $request, Pet $pet): JsonResponse
    {
        if (! $this->petService->canMutate($request->user()?->id, $pet)) {
            return response()->json([
                'success' => false,
                'message' => 'No autorizado',
            ], 403);
        }

        $pet = $this->petService->update($pet, $request->validated());

        return response()->json([
            'success' => true,
            'data' => $pet,
        ]);
    }

    public function destroy(Pet $pet): JsonResponse
    {
        if (! $this->petService->canMutate(request()->user()?->id, $pet)) {
            return response()->json([
                'success' => false,
                'message' => 'No autorizado',
            ], 403);
        }

        $this->petService->delete($pet);

        return response()->json([
            'success' => true,
            'message' => 'Mascota eliminada',
        ]);
    }

    public function markFound(Pet $pet): JsonResponse
    {
        if (! $this->petService->canMutate(request()->user()?->id, $pet)) {
            return response()->json([
                'success' => false,
                'message' => 'No autorizado',
            ], 403);
        }

        $pet = $this->petService->markFound($pet);

        return response()->json([
            'success' => true,
            'data' => $pet,
        ]);
    }
}
