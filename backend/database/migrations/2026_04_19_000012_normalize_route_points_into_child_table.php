<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('route_points', function (Blueprint $table) {
            $table->id();
            $table->foreignId('route_id')->constrained('routes')->cascadeOnDelete();
            $table->unsignedInteger('sequence');
            $table->decimal('latitude', 10, 8);
            $table->decimal('longitude', 11, 8);
            $table->timestamps();

            $table->unique(['route_id', 'sequence']);
            $table->index('route_id');
        });

        DB::table('routes')
            ->select(['id', 'points_json'])
            ->orderBy('id')
            ->chunkById(100, function ($routes): void {
                foreach ($routes as $route) {
                    $points = $this->decodePoints((string) ($route->points_json ?? '[]'));
                    if ($points === []) {
                        continue;
                    }

                    $now = now();
                    $rows = [];
                    foreach ($points as $index => $point) {
                        $rows[] = [
                            'route_id' => $route->id,
                            'sequence' => $index,
                            'latitude' => $point['lat'],
                            'longitude' => $point['lng'],
                            'created_at' => $now,
                            'updated_at' => $now,
                        ];
                    }

                    DB::table('route_points')->insert($rows);
                }
            });

        Schema::table('routes', function (Blueprint $table) {
            $table->dropColumn('points_json');
        });
    }

    public function down(): void
    {
        Schema::table('routes', function (Blueprint $table) {
            $table->longText('points_json')->default('[]')->after('name');
        });

        DB::table('routes')
            ->select('id')
            ->orderBy('id')
            ->chunkById(100, function ($routes): void {
                foreach ($routes as $route) {
                    $points = DB::table('route_points')
                        ->where('route_id', $route->id)
                        ->orderBy('sequence')
                        ->get(['latitude', 'longitude'])
                        ->map(static function ($point): array {
                            return [
                                'lat' => (float) $point->latitude,
                                'lng' => (float) $point->longitude,
                            ];
                        })
                        ->values()
                        ->all();

                    DB::table('routes')
                        ->where('id', $route->id)
                        ->update([
                            'points_json' => json_encode($points, JSON_UNESCAPED_UNICODE),
                        ]);
                }
            });

        Schema::dropIfExists('route_points');
    }

    private function decodePoints(string $json): array
    {
        $decoded = json_decode($json, true);
        if (! is_array($decoded)) {
            return [];
        }

        $points = [];
        foreach ($decoded as $item) {
            if (! is_array($item)) {
                continue;
            }

            $lat = $item['lat'] ?? $item['latitude'] ?? null;
            $lng = $item['lng'] ?? $item['longitude'] ?? null;
            if (! is_numeric($lat) || ! is_numeric($lng)) {
                continue;
            }

            $points[] = [
                'lat' => (float) $lat,
                'lng' => (float) $lng,
            ];
        }

        return $points;
    }
};
