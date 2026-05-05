<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        $now = now();

        DB::table('hazard_categories')->updateOrInsert(
            ['code' => 'pest_presence'],
            ['label' => 'Presencia de plagas', 'sort_order' => 4, 'updated_at' => $now, 'created_at' => $now]
        );
        DB::table('hazard_categories')->updateOrInsert(
            ['code' => 'possible_rabies_vectors'],
            ['label' => 'Posibles transmisores de rabia', 'sort_order' => 5, 'updated_at' => $now, 'created_at' => $now]
        );
        DB::table('hazard_categories')
            ->where('code', 'stagnant_water')
            ->update(['label' => 'Aguas estancadas', 'updated_at' => $now]);
        DB::table('hazard_categories')
            ->where('code', 'waste_accumulation')
            ->update(['label' => 'Acumulación de residuos', 'updated_at' => $now]);

        DB::table('hazard_estimated_durations')
            ->where('code', 'undefined')
            ->update(['label' => 'No lo se', 'updated_at' => $now]);
        DB::table('hazard_estimated_durations')
            ->where('code', '1_day')
            ->update(['label' => '1 Dia', 'updated_at' => $now]);
        DB::table('hazard_estimated_durations')
            ->where('code', '3_days')
            ->update(['label' => '3 Dias', 'updated_at' => $now]);
        DB::table('hazard_estimated_durations')
            ->where('code', '1_week')
            ->update(['label' => '1 Semana', 'updated_at' => $now]);
        DB::table('hazard_estimated_durations')
            ->where('code', '2_weeks')
            ->update(['label' => '2 Semanas', 'updated_at' => $now]);
        DB::table('hazard_estimated_durations')
            ->where('code', '1_month')
            ->update(['label' => '1 Mes', 'updated_at' => $now]);
        DB::table('hazard_estimated_durations')
            ->where('code', '3_months')
            ->update(['label' => '3 Meses', 'updated_at' => $now]);
        DB::table('hazard_estimated_durations')
            ->where('code', '6_months')
            ->update(['label' => '6 Meses', 'updated_at' => $now]);
        DB::table('hazard_estimated_durations')
            ->where('code', '1_year')
            ->update(['label' => '1 Ano', 'updated_at' => $now]);

        $aggressiveId = DB::table('hazard_categories')->where('code', 'aggressive_animals')->value('id');
        $undefinedId = DB::table('hazard_categories')->where('code', 'undefined')->value('id');
        $rabiesId = DB::table('hazard_categories')->where('code', 'possible_rabies_vectors')->value('id');
        $pestId = DB::table('hazard_categories')->where('code', 'pest_presence')->value('id');

        if ($aggressiveId && $rabiesId) {
            DB::table('hazard_reports')->where('category_id', $aggressiveId)->update(['category_id' => $rabiesId]);
        }

        if ($undefinedId && $pestId) {
            DB::table('hazard_reports')->where('category_id', $undefinedId)->update(['category_id' => $pestId]);
        }
    }

    public function down(): void
    {
        $now = now();

        DB::table('hazard_categories')
            ->where('code', 'stagnant_water')
            ->update(['label' => 'Agua estancada', 'updated_at' => $now]);
        DB::table('hazard_categories')
            ->where('code', 'waste_accumulation')
            ->update(['label' => 'Acumulación de residuos', 'updated_at' => $now]);
        DB::table('hazard_estimated_durations')
            ->where('code', 'undefined')
            ->update(['label' => 'Sin definir', 'updated_at' => $now]);
        DB::table('hazard_estimated_durations')
            ->where('code', '1_day')
            ->update(['label' => '1 dia', 'updated_at' => $now]);
        DB::table('hazard_estimated_durations')
            ->where('code', '3_days')
            ->update(['label' => '3 dias', 'updated_at' => $now]);
        DB::table('hazard_estimated_durations')
            ->where('code', '1_week')
            ->update(['label' => '1 semana', 'updated_at' => $now]);
        DB::table('hazard_estimated_durations')
            ->where('code', '2_weeks')
            ->update(['label' => '2 semanas', 'updated_at' => $now]);
        DB::table('hazard_estimated_durations')
            ->where('code', '1_month')
            ->update(['label' => '1 mes', 'updated_at' => $now]);
        DB::table('hazard_estimated_durations')
            ->where('code', '3_months')
            ->update(['label' => '3 meses', 'updated_at' => $now]);
        DB::table('hazard_estimated_durations')
            ->where('code', '6_months')
            ->update(['label' => '6 meses', 'updated_at' => $now]);
        DB::table('hazard_estimated_durations')
            ->where('code', '1_year')
            ->update(['label' => '1 anio', 'updated_at' => $now]);
    }
};
