<?php

namespace App\Services\Pets;

use App\Models\LostPetReport;
use App\Models\Pet;
use App\Services\Concerns\ReportsRemovedLocalSync;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;

class PetService
{
    use ReportsRemovedLocalSync;

    public function paginateForUser(?int $userId, bool $includeArchived, int $perPage, int $page): LengthAwarePaginator
    {
        return $this->queryForUser($userId)->orderByDesc('updated_at')->paginate($perPage, ['*'], 'page', $page);
    }

    public function paginateOwnedForUser(int $userId, int $perPage, int $page): LengthAwarePaginator
    {
        return Pet::query()
            ->where('user_id', $userId)
            ->where('is_ownerless', false)
            ->orderByDesc('updated_at')
            ->paginate($perPage, ['*'], 'page', $page);
    }

    /** @param array<string, mixed> $validated */
    public function store(?int $userId, array $validated): Pet
    {
        return Pet::create($this->payload($validated, ['user_id' => $userId]));
    }

    /** @param array<string, mixed> $validated */
    public function update(Pet $pet, array $validated): Pet
    {
        $pet->update($this->payload($validated, [
            'total_walks' => $validated['total_walks'] ?? $pet->total_walks,
            'registered_at' => $validated['registered_at'] ?? $pet->registered_at ?? $pet->created_at,
            'status' => $this->normalizePetStatus($validated['status'] ?? $pet->status ?? 'normal'),
            'is_ownerless' => (bool) ($validated['is_ownerless'] ?? $pet->is_ownerless),
        ]));

        return $pet->refresh();
    }

    public function delete(Pet $pet): void
    {
        $pet->delete();
    }

    public function markFound(Pet $pet): Pet
    {
        $pet->update(['status' => 'normal']);
        LostPetReport::query()->where('pet_id', $pet->id)->delete();

        return $pet->refresh();
    }

    public function canMutate(?int $userId, Pet $pet): bool
    {
        return $userId !== null && (int) $pet->user_id === (int) $userId;
    }

    /** @param array<int, array<string, mixed>> $pets */
    public function sync(?int $userId, array $pets): array
    {
        return $this->removedLocalSyncResult($pets, withConflicts: true);
    }

    private function queryForUser(?int $userId): Builder
    {
        $query = Pet::query();

        return $userId ? $query->where('user_id', $userId) : $query;
    }

    /** @param array<string, mixed> $validated */
    private function payload(array $validated, array $overrides = []): array
    {
        return $overrides + [
            'name' => $validated['name'] ?? null,
            'photo_path' => $validated['photo_path'] ?? null,
            'total_walks' => $validated['total_walks'] ?? 0,
            'registered_at' => $validated['registered_at'] ?? now(),
            'adoption_date' => $validated['adoption_date'] ?? null,
            'birth_date' => $validated['birth_date'] ?? null,
            'status' => $this->normalizePetStatus($validated['status'] ?? 'normal'),
            'is_ownerless' => (bool) ($validated['is_ownerless'] ?? false),
        ];
    }

    private function normalizePetStatus(string $status): string
    {
        return $status === 'perdida' || $status === 'lost' ? 'perdida' : 'normal';
    }
}
