<?php

namespace App\Http\Controllers;

use App\Http\Requests\Routes\StoreTravelRouteRequest;
use App\Http\Requests\Routes\SyncTravelRoutesRequest;
use App\Http\Requests\Routes\UpdateTravelRouteRequest;
use App\Models\TravelRoute;
use App\Services\Routes\TravelRouteService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TravelRouteController extends Controller
{
    public function __construct(
        private readonly TravelRouteService $travelRouteService
    ) {}

    public function index(Request $request): JsonResponse
    {
        $routes = $this->travelRouteService->paginateForUser(
            $request->user()?->id,
            (bool) $request->query('include_archived'),
            min((int) $request->query('per_page', 50), 100),
            (int) $request->query('page', 1)
        );

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

    public function sync(SyncTravelRoutesRequest $request): JsonResponse
    {
        $results = $this->travelRouteService->sync(
            $request->user()?->id,
            $request->validated('routes')
        );

        return response()->json([
            'success' => true,
            'sync_results' => $results,
        ]);
    }

    public function store(StoreTravelRouteRequest $request): JsonResponse
    {
        $route = $this->travelRouteService->store(
            $request->user()?->id,
            $request->validated()
        );

        return response()->json([
            'success' => true,
            'data' => $route,
        ], 201);
    }

    public function update(UpdateTravelRouteRequest $request, TravelRoute $route): JsonResponse
    {
        $route = $this->travelRouteService->update($route, $request->validated());

        return response()->json([
            'success' => true,
            'data' => $route,
        ]);
    }

    public function destroy(TravelRoute $route): JsonResponse
    {
        $this->travelRouteService->delete($route);

        return response()->json([
            'success' => true,
            'message' => 'Ruta marcada para eliminacion',
        ]);
    }
}
