<?php

namespace App\Services\Routes;

use App\Models\TravelRoute;
use App\Services\Concerns\ReportsRemovedLocalSync;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;

class TravelRouteService
{
    use ReportsRemovedLocalSync;

    public function paginateForUser(?int $userId, bool $includeArchived, int $perPage, int $page): LengthAwarePaginator
    {
        return $this->queryForUser($userId)
            ->with('routePoints')
            ->orderByDesc('updated_at')
            ->paginate($perPage, ['*'], 'page', $page);
    }

    /** @param array<string, mixed> $validated */
    public function store(?int $userId, array $validated): TravelRoute
    {
        return TravelRoute::create([
            'user_id' => $userId,
            'name' => $validated['name'],
            'points_json' => $validated['points_json'],
        ]);
    }

    /** @param array<string, mixed> $validated */
    public function update(TravelRoute $route, array $validated): TravelRoute
    {
        $route->update(['name' => $validated['name'], 'points_json' => $validated['points_json']]);

        return $route->refresh();
    }

    public function delete(TravelRoute $route): void
    {
        $route->delete();
    }

    public function canMutate(?int $userId, TravelRoute $route): bool
    {
        return $userId !== null && (int) $route->user_id === (int) $userId;
    }

    /** @param array<int, array<string, mixed>> $routes */
    public function sync(?int $userId, array $routes): array
    {
        return $this->removedLocalSyncResult($routes, withConflicts: true);
    }

    private function queryForUser(?int $userId): Builder
    {
        return $userId === null || $userId <= 0
            ? TravelRoute::query()->whereRaw('1 = 0')
            : TravelRoute::query()->where('user_id', $userId);
    }
}
