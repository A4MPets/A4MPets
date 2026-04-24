<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('hazard_risk_levels', function (Blueprint $table) {
            $table->id();
            $table->string('code')->unique();
            $table->string('label');
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->timestamps();
        });

        Schema::create('hazard_categories', function (Blueprint $table) {
            $table->id();
            $table->string('code')->unique();
            $table->string('label');
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->timestamps();
        });

        Schema::create('hazard_estimated_durations', function (Blueprint $table) {
            $table->id();
            $table->string('code')->unique();
            $table->string('label');
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->timestamps();
        });

        $this->seedLookupTables();

        Schema::table('hazard_reports', function (Blueprint $table) {
            $table->foreignId('risk_level_id')->nullable()->after('impact_radius_meters')->constrained('hazard_risk_levels')->nullOnDelete();
            $table->foreignId('category_id')->nullable()->after('risk_level_id')->constrained('hazard_categories')->nullOnDelete();
            $table->foreignId('estimated_duration_id')->nullable()->after('category_id')->constrained('hazard_estimated_durations')->nullOnDelete();

            $table->index('risk_level_id');
            $table->index('category_id');
            $table->index('estimated_duration_id');
        });

        $riskByCode = DB::table('hazard_risk_levels')->pluck('id', 'code');
        $categoryByCode = DB::table('hazard_categories')->pluck('id', 'code');
        $durationByCode = DB::table('hazard_estimated_durations')->pluck('id', 'code');

        DB::table('hazard_reports')
            ->orderBy('id')
            ->chunkById(200, function ($rows) use ($riskByCode, $categoryByCode, $durationByCode): void {
                foreach ($rows as $row) {
                    $riskCode = $this->normalizeCode((string) ($row->risk_level_code ?? ''), [
                        'low',
                        'medium',
                        'high',
                        'undefined',
                    ]);
                    $categoryCode = $this->normalizeCode((string) ($row->category_code ?? ''), [
                        'contagious_disease',
                        'stagnant_water',
                        'waste_accumulation',
                        'aggressive_animals',
                        'undefined',
                    ]);
                    $durationCode = $this->normalizeCode((string) ($row->estimated_duration_code ?? ''), [
                        '1_day',
                        '3_days',
                        '1_week',
                        '2_weeks',
                        '1_month',
                        '3_months',
                        '6_months',
                        '1_year',
                        'undefined',
                    ]);

                    DB::table('hazard_reports')
                        ->where('id', $row->id)
                        ->update([
                            'risk_level_id' => $riskByCode[$riskCode] ?? $riskByCode['undefined'],
                            'category_id' => $categoryByCode[$categoryCode] ?? $categoryByCode['undefined'],
                            'estimated_duration_id' => $durationByCode[$durationCode] ?? $durationByCode['undefined'],
                        ]);
                }
            });

        Schema::table('hazard_reports', function (Blueprint $table) {
            $table->dropColumn([
                'risk_level_code',
                'category_code',
                'estimated_duration_code',
            ]);
        });
    }

    public function down(): void
    {
        Schema::table('hazard_reports', function (Blueprint $table) {
            $table->string('risk_level_code')->default('undefined')->after('impact_radius_meters');
            $table->string('category_code')->default('undefined')->after('risk_level_code');
            $table->string('estimated_duration_code')->default('undefined')->after('category_code');
        });

        $riskById = DB::table('hazard_risk_levels')->pluck('code', 'id');
        $categoryById = DB::table('hazard_categories')->pluck('code', 'id');
        $durationById = DB::table('hazard_estimated_durations')->pluck('code', 'id');

        DB::table('hazard_reports')
            ->orderBy('id')
            ->chunkById(200, function ($rows) use ($riskById, $categoryById, $durationById): void {
                foreach ($rows as $row) {
                    DB::table('hazard_reports')
                        ->where('id', $row->id)
                        ->update([
                            'risk_level_code' => $riskById[$row->risk_level_id] ?? 'undefined',
                            'category_code' => $categoryById[$row->category_id] ?? 'undefined',
                            'estimated_duration_code' => $durationById[$row->estimated_duration_id] ?? 'undefined',
                        ]);
                }
            });

        Schema::table('hazard_reports', function (Blueprint $table) {
            $table->dropForeign(['risk_level_id']);
            $table->dropForeign(['category_id']);
            $table->dropForeign(['estimated_duration_id']);
            $table->dropIndex(['risk_level_id']);
            $table->dropIndex(['category_id']);
            $table->dropIndex(['estimated_duration_id']);
            $table->dropColumn([
                'risk_level_id',
                'category_id',
                'estimated_duration_id',
            ]);
        });

        Schema::dropIfExists('hazard_estimated_durations');
        Schema::dropIfExists('hazard_categories');
        Schema::dropIfExists('hazard_risk_levels');
    }

    private function seedLookupTables(): void
    {
        $now = now();

        DB::table('hazard_risk_levels')->insert([
            ['code' => 'undefined', 'label' => 'Sin definir', 'sort_order' => 0, 'created_at' => $now, 'updated_at' => $now],
            ['code' => 'low', 'label' => 'Bajo', 'sort_order' => 1, 'created_at' => $now, 'updated_at' => $now],
            ['code' => 'medium', 'label' => 'Medio', 'sort_order' => 2, 'created_at' => $now, 'updated_at' => $now],
            ['code' => 'high', 'label' => 'Alto', 'sort_order' => 3, 'created_at' => $now, 'updated_at' => $now],
        ]);

        DB::table('hazard_categories')->insert([
            ['code' => 'undefined', 'label' => 'Sin definir', 'sort_order' => 0, 'created_at' => $now, 'updated_at' => $now],
            ['code' => 'contagious_disease', 'label' => 'Enfermedad contagiosa', 'sort_order' => 1, 'created_at' => $now, 'updated_at' => $now],
            ['code' => 'stagnant_water', 'label' => 'Agua estancada', 'sort_order' => 2, 'created_at' => $now, 'updated_at' => $now],
            ['code' => 'waste_accumulation', 'label' => 'Acumulacion de residuos', 'sort_order' => 3, 'created_at' => $now, 'updated_at' => $now],
            ['code' => 'aggressive_animals', 'label' => 'Animales agresivos', 'sort_order' => 4, 'created_at' => $now, 'updated_at' => $now],
        ]);

        DB::table('hazard_estimated_durations')->insert([
            ['code' => 'undefined', 'label' => 'Sin definir', 'sort_order' => 0, 'created_at' => $now, 'updated_at' => $now],
            ['code' => '1_day', 'label' => '1 dia', 'sort_order' => 1, 'created_at' => $now, 'updated_at' => $now],
            ['code' => '3_days', 'label' => '3 dias', 'sort_order' => 2, 'created_at' => $now, 'updated_at' => $now],
            ['code' => '1_week', 'label' => '1 semana', 'sort_order' => 3, 'created_at' => $now, 'updated_at' => $now],
            ['code' => '2_weeks', 'label' => '2 semanas', 'sort_order' => 4, 'created_at' => $now, 'updated_at' => $now],
            ['code' => '1_month', 'label' => '1 mes', 'sort_order' => 5, 'created_at' => $now, 'updated_at' => $now],
            ['code' => '3_months', 'label' => '3 meses', 'sort_order' => 6, 'created_at' => $now, 'updated_at' => $now],
            ['code' => '6_months', 'label' => '6 meses', 'sort_order' => 7, 'created_at' => $now, 'updated_at' => $now],
            ['code' => '1_year', 'label' => '1 anio', 'sort_order' => 8, 'created_at' => $now, 'updated_at' => $now],
        ]);
    }

    private function normalizeCode(string $value, array $allowed): string
    {
        $normalized = strtolower(trim($value));
        if ($normalized === '' || $normalized === 'unknown' || $normalized === 'unspecified') {
            return 'undefined';
        }

        return in_array($normalized, $allowed, true) ? $normalized : 'undefined';
    }
};
