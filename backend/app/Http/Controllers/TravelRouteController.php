<?php

namespace App\Http\Controllers;

use App\Models\TravelRoute;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class TravelRouteController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $userId = $request->user()?->id;

        $query = TravelRoute::query()->with('routePoints')->where(function ($builder) use ($userId): void {
            if ($userId) {
                $builder->where('user_id', $userId);
            } else {
                $builder->whereNull('user_id');
            }
        })->where('sync_status', '!=', 'deleted');

        $perPage = min((int) $request->query('per_page', 50), 100);
        $page = (int) $request->query('page', 1);

        $routes = $query->orderBy('last_modified_at', 'desc')
            ->paginate($perPage, ['*'], 'page', $page);

        return response()->json([
            'success' => true,
            'data' => $routes->items(),
            'pagination' => [
                'total' => $routes->total(),
                'per_page' => $routes->perPage(),
                'current_page' => $routes->currentPage(),
                'last_page' => $routes->lastPage(),
            ],
        ]);
    }

    public function sync(Request $request): JsonResponse
    {
        $userId = $request->user()?->id;
        $validated = $request->validate([
            'routes' => ['required', 'array'],
            'routes.*.local_id' => ['required', 'string'],
            'routes.*.remote_id' => ['nullable', 'string'],
            'routes.*.name' => ['required', 'string', 'max:255'],
            'routes.*.points_json' => ['required', 'string'],
            'routes.*.sync_status' => ['required', 'string', 'max:32'],
            'routes.*.last_modified_at' => ['required', 'date_format:Y-m-d H:i:s'],
        ]);

        $results = [
            'synced' => 0,
            'deleted' => 0,
            'conflicts' => 0,
            'errors' => 0,
            'details' => [],
        ];

        foreach ($validated['routes'] as $routeData) {
            try {
                $route = TravelRoute::query()
                    ->where(function ($builder) use ($userId, $routeData): void {
                        if ($userId) {
                            $builder->where('user_id', $userId);
                        } else {
                            $builder->whereNull('user_id');
                        }
                        $builder->where('local_id', $routeData['local_id']);
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

                $route->update([
                    'remote_id' => $route->remote_id ?? (string) $route->id,
                ]);

                $results['synced']++;
            } catch (\Throwable $error) {
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
            'points_json' => ['required', 'string'],
        ]);

        $userId = $request->user()?->id;

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

        $route->update([
            'remote_id' => $route->remote_id ?? (string) $route->id,
        ]);

        return response()->json([
            'success' => true,
            'data' => $route,
        ], 201);
    }

    public function update(Request $request, TravelRoute $route): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'points_json' => ['required', 'string'],
        ]);

        $route->update([
            'name' => $validated['name'],
            'points_json' => $validated['points_json'],
            'sync_status' => 'synced',
            'last_modified_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'data' => $route->refresh(),
        ]);
    }

    public function destroy(TravelRoute $route): JsonResponse
    {
        $route->update([
            'sync_status' => 'deleted',
            'last_modified_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Ruta marcada para eliminación',
        ]);
    }
}
