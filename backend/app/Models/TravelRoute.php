<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class TravelRoute extends Model
{
    protected $table = 'routes';

    protected $fillable = [
        'user_id',
        'local_id',
        'remote_id',
        'name',
        'points_json',
        'sync_status',
        'last_modified_at',
        'synced_at',
    ];

    protected $appends = [
        'points_json',
    ];

    protected $casts = [
        'last_modified_at' => 'datetime',
        'synced_at' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    private ?array $pendingPoints = null;

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function routePoints(): HasMany
    {
        return $this->hasMany(RoutePoint::class, 'route_id')->orderBy('sequence');
    }

    public function getPointsJsonAttribute(): string
    {
        $points = $this->relationLoaded('routePoints')
            ? $this->routePoints
            : $this->routePoints()->orderBy('sequence')->get();

        return json_encode($points->map(static function (RoutePoint $point): array {
            return [
                'lat' => (float) $point->latitude,
                'lng' => (float) $point->longitude,
            ];
        })->values()->all(), JSON_UNESCAPED_UNICODE);
    }

    public function setPointsJsonAttribute(mixed $value): void
    {
        $this->pendingPoints = self::decodePoints($value);
    }

    protected static function booted(): void
    {
        static::saved(function (self $route): void {
            if ($route->pendingPoints === null) {
                return;
            }

            $route->routePoints()->delete();

            if ($route->pendingPoints !== []) {
                $rows = [];
                $now = now();
                foreach ($route->pendingPoints as $index => $point) {
                    $rows[] = [
                        'route_id' => $route->id,
                        'sequence' => $index,
                        'latitude' => $point['lat'],
                        'longitude' => $point['lng'],
                        'created_at' => $now,
                        'updated_at' => $now,
                    ];
                }
                RoutePoint::query()->insert($rows);
            }

            $route->pendingPoints = null;
            $route->unsetRelation('routePoints');
        });
    }

    private static function decodePoints(mixed $value): array
    {
        $rawPoints = [];

        if (is_string($value)) {
            $decoded = json_decode($value, true);
            $rawPoints = is_array($decoded) ? $decoded : [];
        } elseif (is_array($value)) {
            $rawPoints = $value;
        }

        $normalizedPoints = [];
        foreach ($rawPoints as $point) {
            if (! is_array($point)) {
                continue;
            }

            $lat = $point['lat'] ?? $point['latitude'] ?? null;
            $lng = $point['lng'] ?? $point['longitude'] ?? null;
            if (! is_numeric($lat) || ! is_numeric($lng)) {
                continue;
            }

            $normalizedPoints[] = [
                'lat' => (float) $lat,
                'lng' => (float) $lng,
            ];
        }

        return $normalizedPoints;
    }
}
