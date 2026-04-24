<?php

namespace App\Http\Controllers;

use App\Models\Pet;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\ValidationException;

class PetController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $userId = $request->user()?->id;

        $query = Pet::query()->where(function ($builder) use ($userId): void {
            if ($userId) {
                $builder->where('user_id', $userId);
            } else {
                $builder->whereNull('user_id');
            }
        });

        if (!$request->query('include_archived')) {
            $query->where('sync_status', '!=', 'deleted');
        }

        $perPage = min((int) $request->query('per_page', 50), 100);
        $page = (int) $request->query('page', 1);

        $pets = $query->orderBy('last_modified_at', 'desc')
            ->paginate($perPage, ['*'], 'page', $page);

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

    public function sync(Request $request): JsonResponse
    {
        $userId = $request->user()?->id;
        $validated = $request->validate([
            'pets' => ['required', 'array'],
            'pets.*.local_id' => ['required', 'string'],
            'pets.*.remote_id' => ['nullable', 'string'],
            'pets.*.name' => ['required', 'string', 'max:255'],
            'pets.*.photo_path' => ['nullable', 'string', 'max:500'],
            'pets.*.sync_status' => ['required', 'string', 'max:32'],
            'pets.*.last_modified_at' => ['required', 'date_format:Y-m-d H:i:s'],
        ]);

        $results = [
            'synced' => 0,
            'deleted' => 0,
            'conflicts' => 0,
            'errors' => 0,
            'details' => [],
        ];

        foreach ($validated['pets'] as $petData) {
            try {
                $pet = Pet::query()
                    ->where(function ($builder) use ($userId, $petData): void {
                        if ($userId) {
                            $builder->where('user_id', $userId);
                        } else {
                            $builder->whereNull('user_id');
                        }
                        $builder->where(function ($q) use ($petData): void {
                            if (!empty($petData['remote_id'])) {
                                $q->where('remote_id', $petData['remote_id'])
                                  ->orWhere('id', $petData['remote_id']);
                            }
                            $q->orWhere('local_id', $petData['local_id']);
                        });
                    })
                    ->first();

                if (($petData['sync_status'] ?? 'created') === 'deleted') {
                    if ($pet) {
                        $pet->update([
                            'sync_status' => 'deleted',
                            'last_modified_at' => $petData['last_modified_at'],
                            'synced_at' => now(),
                        ]);
                    }
                    $results['deleted']++;
                    continue;
                }

                $payload = [
                    'name' => $petData['name'],
                    'photo_path' => $petData['photo_path'] ?? null,
                    'sync_status' => 'synced',
                    'last_modified_at' => $petData['last_modified_at'],
                    'synced_at' => now(),
                ];

                if ($pet) {
                    $pet->update($payload);
                } else {
                    $payload['user_id'] = $userId;
                    $payload['local_id'] = $petData['local_id'];
                    $pet = Pet::create($payload);
                }

                $pet->update([
                    'remote_id' => $pet->remote_id ?? (string) $pet->id,
                ]);

                $results['synced']++;
            } catch (\Throwable $error) {
                Log::error('Pet sync item error', [
                    'local_id' => $petData['local_id'] ?? 'unknown',
                    'error' => $error->getMessage(),
                ]);
                $results['errors']++;
                $results['details'][] = [
                    'local_id' => $petData['local_id'] ?? 'unknown',
                    'status' => 'error',
                    'error' => $error->getMessage(),
                ];
            }
        }

        return response()->json([
            'success' => true,
            'sync_results' => $results,
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'local_id' => ['required', 'string'],
            'name' => ['required', 'string', 'max:255'],
            'photo_path' => ['nullable', 'string', 'max:500'],
        ]);

        $userId = $request->user()?->id;

        $pet = Pet::updateOrCreate(
            [
                'user_id' => $userId,
                'local_id' => $validated['local_id'],
            ],
            [
                'name' => $validated['name'],
                'photo_path' => $validated['photo_path'] ?? null,
                'sync_status' => 'synced',
                'last_modified_at' => now(),
                'synced_at' => now(),
            ]
        );

        $pet->update([
            'remote_id' => $pet->remote_id ?? (string) $pet->id,
        ]);

        return response()->json([
            'success' => true,
            'data' => $pet,
        ], 201);
    }

    public function update(Request $request, Pet $pet): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'photo_path' => ['nullable', 'string', 'max:500'],
        ]);

        $pet->update([
            'name' => $validated['name'],
            'photo_path' => $validated['photo_path'] ?? null,
            'sync_status' => 'synced',
            'last_modified_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'data' => $pet->refresh(),
        ]);
    }

    public function destroy(Pet $pet): JsonResponse
    {
        $pet->update([
            'sync_status' => 'deleted',
            'last_modified_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Mascota marcada para eliminación',
        ]);
    }
}
