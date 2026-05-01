<?php

namespace App\Services\Pets;

use App\Models\Pet;
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

        $this->ensureRemoteId($pet);

        return $pet;
    }

    /**
     * @param  array<string, mixed>  $validated
     */
    public function update(Pet $pet, array $validated): Pet
    {
        $pet->update([
            'name' => $validated['name'],
            'photo_path' => $validated['photo_path'] ?? null,
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

                $this->ensureRemoteId($pet);
                $results['synced']++;
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
        ]);
    }
}
