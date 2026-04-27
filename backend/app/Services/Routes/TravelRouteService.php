<?php

namespace App\Services\Routes;

use App\Models\TravelRoute;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\Log;
use Throwable;

class TravelRouteService
{
    public function paginateForUser(?int $userId, bool $includeArchived, int $perPage, int $page): LengthAwarePaginator
    {
        $query = $this->queryForUser($userId);

        if (! $includeArchived) {
            $query->where('sync_status', '!=', 'deleted');
        }

        return $query
            ->with('routePoints')
            ->orderByDesc('last_modified_at')
            ->paginate($perPage, ['*'], 'page', $page);
    }

    /**
     * @param  array<string, mixed>  $validated
     */
    public function store(?int $userId, array $validated): TravelRoute
    {
        $route = TravelRoute::updateOrCreate(
            [
                'user_id' => $userId,
                'local_id' => $validated['local_id'],
            ],
            [
                'name' => $validated['name'],
                'points_json' => $validated['points_json'],
                'sync_status' => 'synced',
                'last_modified_at' => now(),
                'synced_at' => now(),
            ]
        );

        $this->ensureRemoteId($route);

        return $route;
    }

    /**
     * @param  array<string, mixed>  $validated
     */
    public function update(TravelRoute $route, array $validated): TravelRoute
    {
        $route->update([
            'name' => $validated['name'],
            'points_json' => $validated['points_json'],
            'sync_status' => 'synced',
            'last_modified_at' => now(),
        ]);

        return $route->refresh();
    }

    public function delete(TravelRoute $route): void
    {
        $route->update([
            'sync_status' => 'deleted',
            'last_modified_at' => now(),
        ]);
    }

    /**
     * @param  array<int, array<string, mixed>>  $routes
     * @return array<string, mixed>
     */
    public function sync(?int $userId, array $routes): array
    {
        $results = [
            'synced' => 0,
            'deleted' => 0,
            'conflicts' => 0,
            'errors' => 0,
            'details' => [],
        ];

        foreach ($routes as $routeData) {
            try {
                $route = $this->queryForUser($userId)
                    ->where(function (Builder $query) use ($routeData): void {
                        if (! empty($routeData['remote_id'])) {
                            $query->where('remote_id', $routeData['remote_id'])
                                ->orWhere('id', $routeData['remote_id']);
                        }

                        $query->orWhere('local_id', $routeData['local_id']);
                    })
                    ->first();

                if (($routeData['sync_status'] ?? 'created') === 'deleted') {
                    if ($route) {
                        $route->update([
                            'sync_status' => 'deleted',
                            'last_modified_at' => $routeData['last_modified_at'],
                            'synced_at' => now(),
                        ]);
                    }

                    $results['deleted']++;

                    continue;
                }

                $payload = [
                    'name' => $routeData['name'],
                    'points_json' => $routeData['points_json'],
                    'sync_status' => 'synced',
                    'last_modified_at' => $routeData['last_modified_at'],
                    'synced_at' => now(),
                ];

                if ($route) {
                    $route->update($payload);
                } else {
                    $payload['user_id'] = $userId;
                    $payload['local_id'] = $routeData['local_id'];
                    $route = TravelRoute::create($payload);
                }

                $this->ensureRemoteId($route);
                $results['synced']++;
            } catch (Throwable $error) {
                Log::error('Route sync item error', [
                    'local_id' => $routeData['local_id'] ?? 'unknown',
                    'error' => $error->getMessage(),
                ]);

                $results['errors']++;
                $results['details'][] = [
                    'local_id' => $routeData['local_id'] ?? 'unknown',
                    'status' => 'error',
                    'error' => $error->getMessage(),
                ];
            }
        }

        return $results;
    }

    private function queryForUser(?int $userId): Builder
    {
        return TravelRoute::query()->where(function (Builder $query) use ($userId): void {
            if ($userId) {
                $query->where('user_id', $userId);
            } else {
                $query->whereNull('user_id');
            }
        });
    }

    private function ensureRemoteId(TravelRoute $route): void
    {
        $route->update([
            'remote_id' => $route->remote_id ?? (string) $route->id,
        ]);
    }
}
