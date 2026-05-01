<?php

namespace App\Services\Pets;

use App\Models\Pet;
use App\Models\LostPetReport;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\Log;
use Throwable;

class PetService
{
    public function paginateForUser(?int $userId, bool $includeArchived, int $perPage, int $page): LengthAwarePaginator
    {
        $query = $this->queryForUser($userId);

        if (! $includeArchived) {
            $query->where('sync_status', '!=', 'deleted');
        }

        return $query
            ->orderByDesc('last_modified_at')
            ->paginate($perPage, ['*'], 'page', $page);
    }

    /**
     * @param  array<string, mixed>  $validated
     */
    public function store(?int $userId, array $validated): Pet
    {
        $localUuid = $validated['local_uuid'] ?? $validated['local_id'];
        $pet = Pet::updateOrCreate(
            [
                'user_id' => $userId,
                'local_id' => $validated['local_id'],
            ],
            [
                'local_uuid' => $localUuid,
                'name' => $validated['name'] ?? null,
                'photo_path' => $validated['photo_path'] ?? null,
                'total_walks' => $validated['total_walks'] ?? 0,
                'registered_at' => $validated['registered_at'] ?? now(),
                'adoption_date' => $validated['adoption_date'] ?? null,
                'birth_date' => $validated['birth_date'] ?? null,
                'status' => $this->normalizePetStatus($validated['status'] ?? 'normal'),
                'is_ownerless' => (bool) ($validated['is_ownerless'] ?? false),
                'sync_status' => 'synced',
                'last_modified_at' => now(),
                'synced_at' => now(),
            ]
        );

        $this->ensureRemoteId($pet);

        return $pet;
    }

    /**
     * @param  array<string, mixed>  $validated
     */
    public function update(Pet $pet, array $validated): Pet
    {
        $pet->update([
            'name' => $validated['name'] ?? null,
            'photo_path' => $validated['photo_path'] ?? null,
            'total_walks' => $validated['total_walks'] ?? $pet->total_walks,
            'registered_at' => $validated['registered_at'] ?? $pet->registered_at ?? $pet->created_at,
            'adoption_date' => $validated['adoption_date'] ?? null,
            'birth_date' => $validated['birth_date'] ?? null,
            'status' => $this->normalizePetStatus($validated['status'] ?? $pet->status ?? 'normal'),
            'is_ownerless' => (bool) ($validated['is_ownerless'] ?? $pet->is_ownerless),
            'sync_status' => 'synced',
            'last_modified_at' => now(),
        ]);

        return $pet->refresh();
    }

    public function delete(Pet $pet): void
    {
        $pet->update([
            'sync_status' => 'deleted',
            'last_modified_at' => now(),
        ]);
    }

    public function markFound(Pet $pet): Pet
    {
        $pet->update([
            'status' => 'normal',
            'sync_status' => 'synced',
            'last_modified_at' => now(),
            'synced_at' => now(),
        ]);

        LostPetReport::query()
            ->where('pet_id', $pet->id)
            ->where('sync_status', '!=', 'deleted')
            ->update([
                'sync_status' => 'deleted',
                'last_modified_at' => now(),
                'synced_at' => now(),
            ]);

        return $pet->refresh();
    }

    /**
     * @param  array<int, array<string, mixed>>  $pets
     * @return array<string, mixed>
     */
    public function sync(?int $userId, array $pets): array
    {
        $results = [
            'synced' => 0,
            'deleted' => 0,
            'conflicts' => 0,
            'errors' => 0,
            'details' => [],
        ];

        foreach ($pets as $petData) {
            try {
                $pet = $this->queryForUser($userId)
                    ->where(function (Builder $query) use ($petData): void {
                        if (! empty($petData['remote_id'])) {
                            $query->where('remote_id', $petData['remote_id'])
                                ->orWhere('id', $petData['remote_id']);
                        }

                        $query->orWhere('local_id', $petData['local_id']);
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

                $localUuid = $petData['local_uuid'] ?? $petData['local_id'];
                $payload = [
                    'local_uuid' => $localUuid,
                    'name' => $petData['name'] ?? null,
                    'photo_path' => $petData['photo_path'] ?? null,
                    'total_walks' => $petData['total_walks'] ?? 0,
                    'registered_at' => $petData['registered_at'] ?? $petData['last_modified_at'],
                    'adoption_date' => $petData['adoption_date'] ?? null,
                    'birth_date' => $petData['birth_date'] ?? null,
                    'status' => $this->normalizePetStatus($petData['status'] ?? 'normal'),
                    'is_ownerless' => (bool) ($petData['is_ownerless'] ?? false),
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

                $this->ensureRemoteId($pet);
                $results['synced']++;
                $results['details'][] = [
                    'local_id' => $petData['local_id'],
                    'remote_id' => $pet->remote_id,
                    'status' => 'synced',
                ];
            } catch (Throwable $error) {
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

        return $results;
    }

    private function queryForUser(?int $userId): Builder
    {
        return Pet::query()->where(function (Builder $query) use ($userId): void {
            if ($userId) {
                $query->where('user_id', $userId);
            } else {
                $query->whereNull('user_id');
            }
        });
    }

    private function ensureRemoteId(Pet $pet): void
    {
        $pet->update([
            'remote_id' => $pet->remote_id ?? (string) $pet->id,
            'local_uuid' => $pet->local_uuid ?? $pet->local_id,
        ]);
    }

    private function normalizePetStatus(string $status): string
    {
        return $status === 'perdida' || $status === 'lost' ? 'perdida' : 'normal';
    }
}
