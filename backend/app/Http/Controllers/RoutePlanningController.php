<?php

namespace App\Http\Controllers;

use App\Services\GraphHopperRoutingService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Throwable;

class RoutePlanningController extends Controller
{
    public function __construct(
        private readonly GraphHopperRoutingService $routingService
    ) {}

    public function plan(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'points' => 'required|array|min:2',
            'points.*.lat' => 'required|numeric|between:-90,90',
            'points.*.lng' => 'required|numeric|between:-180,180',
            'avoid_hazards' => 'sometimes|boolean',
            'hazard_risk_filters' => 'sometimes|array',
            'hazard_risk_filters.*' => 'string|in:low,medium,high,other',
            'travel_mode' => 'sometimes|string|max:32',
            'trip_config' => 'sometimes|array',
        ]);

        $avoidHazards = (bool) ($validated['avoid_hazards'] ?? false);
        $hazardRiskFilters = $validated['hazard_risk_filters'] ?? null;
        $travelMode = (string) ($validated['travel_mode'] ?? 'walking');

        try {
            $route = $this->routingService->planRoute(
                points: $validated['points'],
                avoidHazards: $avoidHazards,
                hazardRiskFilters: is_array($hazardRiskFilters) ? $hazardRiskFilters : null,
                travelMode: $travelMode
            );

            return response()->json([
                'success' => true,
                'data' => [
                    'coordinates' => $route['coordinates'],
                    'distance_meters' => $route['distance_meters'],
                    'duration_seconds' => $route['duration_seconds'],
                    'profile' => $route['profile'],
                    'used_hazard_avoidance' => $avoidHazards,
                    'hazards_considered' => $route['hazards_considered'],
                    'navigation_instructions' => $route['navigation_instructions'],
                ],
                'meta' => [
                    'travel_mode' => $travelMode,
                    'hazard_risk_filters' => $route['hazard_risk_filters'],
                    // Recibimos configuración completa de viaje para compatibilidad futura.
                    'trip_config' => $validated['trip_config'] ?? new \stdClass,
                ],
            ]);
        } catch (Throwable $e) {
            Log::error('Route plan failed', [
                'message' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return response()->json([
                'success' => false,
                'message' => 'No se pudo calcular la ruta en este momento.',
                'error' => $e->getMessage(),
            ], 502);
        }
    }
}
