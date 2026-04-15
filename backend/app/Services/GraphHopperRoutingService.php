<?php

namespace App\Services;

use App\Models\HazardReport;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use RuntimeException;
use Throwable;

class GraphHopperRoutingService
{
    public function planRoute(array $points, bool $avoidHazards, string $travelMode): array
    {
        $baseUrls = $this->resolveBaseUrls();
        $apiKey = (string) config('services.graphhopper.api_key');

        if (count($baseUrls) === 0) {
            throw new RuntimeException('GraphHopper no está configurado en services.graphhopper.base_url.');
        }

        $profiles = $this->mapTravelModeToProfiles($travelMode);
        $attempts = [];

        foreach ($profiles as $profile) {
            $routeRequest = $this->buildPayload($points, $profile, $avoidHazards);
            $payload = $routeRequest['payload'];
            $hazardsConsidered = $routeRequest['hazards_considered'];

            $query = [];
            if ($avoidHazards) {
                // custom_model no es compatible con speed mode (CH).
                $query[] = 'ch.disable=true';
            }
            if ($apiKey !== '') {
                $query[] = 'key=' . urlencode($apiKey);
            }

            foreach ($baseUrls as $baseUrl) {
                $requestUrl = $baseUrl . '/route';
                if (!empty($query)) {
                    $requestUrl .= '?' . implode('&', $query);
                }

                try {
                    $response = Http::timeout(20)
                        ->acceptJson()
                        ->post($requestUrl, $payload);
                } catch (Throwable $e) {
                    $attempts[] = $profile . '@' . $baseUrl . ': ' . $e->getMessage();
                    Log::warning('GraphHopper connection attempt failed', [
                        'url' => $requestUrl,
                        'profile' => $profile,
                        'message' => $e->getMessage(),
                    ]);
                    continue;
                }

                if (!$response->successful()) {
                    $attempts[] = $profile . '@' . $baseUrl . ': HTTP ' . $response->status();
                    Log::warning('GraphHopper request failed', [
                        'url' => $requestUrl,
                        'profile' => $profile,
                        'status' => $response->status(),
                        'body' => $response->body(),
                    ]);
                    continue;
                }

                $body = $response->json();
                $firstPath = $body['paths'][0] ?? null;

                if ($firstPath === null) {
                    $attempts[] = $profile . '@' . $baseUrl . ': sin paths';
                    continue;
                }

                $coordinates = $firstPath['points']['coordinates'] ?? [];
                if (!is_array($coordinates) || count($coordinates) === 0) {
                    $attempts[] = $profile . '@' . $baseUrl . ': geometria vacia';
                    continue;
                }

                return [
                    'coordinates' => $coordinates,
                    'distance_meters' => (float) ($firstPath['distance'] ?? 0.0),
                    'duration_seconds' => ((float) ($firstPath['time'] ?? 0.0)) / 1000.0,
                    'profile' => $profile,
                    'hazards_considered' => $hazardsConsidered,
                ];
            }
        }

        throw new RuntimeException(
            'No se pudo calcular la ruta con GraphHopper. Intentos: ' . implode(' | ', $attempts)
        );
    }

    private function resolveBaseUrls(): array
    {
        $configured = trim((string) config('services.graphhopper.base_url'));
        $urls = [
            $configured,
            'http://graphhopper:8989',
            'http://127.0.0.1:8989',
        ];

        $normalized = [];
        foreach ($urls as $url) {
            if ($url === '') {
                continue;
            }

            $clean = rtrim($url, '/');
            if (!in_array($clean, $normalized, true)) {
                $normalized[] = $clean;
            }
        }

        return $normalized;
    }

    private function buildPayload(array $points, string $profile, bool $avoidHazards): array
    {
        $payload = [
            'profile' => $profile,
            'points' => array_map(
                static fn (array $p): array => [(float) $p['lng'], (float) $p['lat']],
                $points
            ),
            'points_encoded' => false,
            'instructions' => false,
            'calc_points' => true,
        ];

        if (!$avoidHazards) {
            return [
                'payload' => $payload,
                'hazards_considered' => 0,
            ];
        }

        $payload['ch.disable'] = true;

        $hazards = HazardReport::query()
            ->where('status', '!=', 'archived')
            ->whereNotNull('incident_latitude')
            ->whereNotNull('incident_longitude')
            ->whereNotNull('impact_radius_meters')
            ->orderByDesc('last_modified_at')
            ->limit(30)
            ->get([
                'incident_latitude',
                'incident_longitude',
                'impact_radius_meters',
            ]);

        if ($hazards->isEmpty()) {
            return [
                'payload' => $payload,
                'hazards_considered' => 0,
            ];
        }

        $areas = [];
        $priorityRules = [];
        $index = 0;

        foreach ($hazards as $hazard) {
            $index++;
            $areaName = 'hz_' . $index;

            $polygon = $this->buildCirclePolygon(
                (float) $hazard->incident_latitude,
                (float) $hazard->incident_longitude,
                max(10.0, (float) $hazard->impact_radius_meters),
                20
            );

            $areas[$areaName] = [
                'type' => 'Feature',
                'geometry' => [
                    'type' => 'Polygon',
                    'coordinates' => [$polygon],
                ],
                'properties' => (object) [],
            ];

            $priorityRules[] = [
                'if' => 'in_' . $areaName,
                'multiply_by' => '0.01',
            ];
        }

        $payload['custom_model'] = [
            'areas' => $areas,
            'priority' => $priorityRules,
        ];

        return [
            'payload' => $payload,
            'hazards_considered' => count($priorityRules),
        ];
    }

    private function mapTravelModeToProfiles(string $travelMode): array
    {
        $mode = strtolower(trim($travelMode));

        if (in_array($mode, ['walking', 'walk', 'on_foot', 'foot'], true)) {
            return ['foot', 'car'];
        }

        if (in_array($mode, ['vehicle', 'driving', 'car'], true)) {
            return ['car'];
        }

        return ['car', 'foot'];
    }

    private function buildCirclePolygon(float $lat, float $lng, float $radiusMeters, int $segments): array
    {
        $earthRadius = 6371000.0;
        $latRad = deg2rad($lat);
        $lngRad = deg2rad($lng);
        $angularDistance = $radiusMeters / $earthRadius;

        $coordinates = [];
        for ($i = 0; $i <= $segments; $i++) {
            $bearing = 2 * M_PI * ($i / $segments);
            $targetLat = asin(
                sin($latRad) * cos($angularDistance) +
                cos($latRad) * sin($angularDistance) * cos($bearing)
            );

            $targetLng = $lngRad + atan2(
                sin($bearing) * sin($angularDistance) * cos($latRad),
                cos($angularDistance) - sin($latRad) * sin($targetLat)
            );

            $coordinates[] = [rad2deg($targetLng), rad2deg($targetLat)];
        }

        return $coordinates;
    }
}
