<?php

namespace App\Http\Controllers;

use App\Http\Requests\Pets\StorePetRequest;
use App\Http\Requests\Pets\SyncPetsRequest;
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
        $pets = $this->petService->paginateForUser(
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

    public function sync(SyncPetsRequest $request): JsonResponse
    {
        $results = $this->petService->sync(
            $request->user()?->id,
            $request->validated('pets')
        );

        return response()->json([
            'success' => true,
            'sync_results' => $results,
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
        $pet = $this->petService->update($pet, $request->validated());

        return response()->json([
            'success' => true,
            'data' => $pet,
        ]);
    }

    public function destroy(Pet $pet): JsonResponse
    {
        $this->petService->delete($pet);

        return response()->json([
            'success' => true,
            'message' => 'Mascota marcada para eliminacion',
        ]);
    }
}
