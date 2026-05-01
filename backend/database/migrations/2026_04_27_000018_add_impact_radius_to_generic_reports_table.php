<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasColumn('generic_reports', 'impact_radius_meters')) {
            Schema::table('generic_reports', function (Blueprint $table): void {
                $table->unsignedInteger('impact_radius_meters')->default(0)->after('risk_level_code');
            });
        }

        DB::table('generic_reports')
            ->whereNull('impact_radius_meters')
            ->update(['impact_radius_meters' => 0]);
    }

    public function down(): void
    {
        if (Schema::hasColumn('generic_reports', 'impact_radius_meters')) {
            Schema::table('generic_reports', function (Blueprint $table): void {
                $table->dropColumn('impact_radius_meters');
            });
        }
    }
};
