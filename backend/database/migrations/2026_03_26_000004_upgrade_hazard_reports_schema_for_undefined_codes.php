<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        $driver = DB::getDriverName();

        if ($driver === 'sqlite') {
            $this->rebuildSqliteHazardReportsTable();
            return;
        }

        Schema::table('hazard_reports', function (Blueprint $table) {
            if (!Schema::hasColumn('hazard_reports', 'category_code')) {
                $table->string('category_code')->default('undefined')->after('risk_level_code');
            }
            if (!Schema::hasColumn('hazard_reports', 'estimated_duration_code')) {
                $table->string('estimated_duration_code')->default('undefined')->after('category_code');
            }
            if (!Schema::hasColumn('hazard_reports', 'narrative_description')) {
                $table->string('narrative_description')->nullable()->after('description');
            }
            if (!Schema::hasColumn('hazard_reports', 'reported_at')) {
                $table->timestamp('reported_at')->nullable()->after('narrative_description');
            }
            if (!Schema::hasColumn('hazard_reports', 'evidence_photo_url')) {
                $table->string('evidence_photo_url')->nullable()->after('reported_at');
            }
            if (!Schema::hasColumn('hazard_reports', 'reported_by_username')) {
                $table->string('reported_by_username')->default('Anónimo')->after('evidence_photo_url');
            }
        });

        // MySQL/MariaDB: relajar risk_level_code para permitir "undefined".
        try {
            DB::statement("ALTER TABLE hazard_reports MODIFY risk_level_code VARCHAR(32) NOT NULL DEFAULT 'undefined'");
        } catch (\Throwable $e) {
            // Si el motor no soporta MODIFY, mantenemos columnas agregadas y continuamos.
        }

        DB::table('hazard_reports')->update([
            'risk_level_code' => DB::raw("CASE WHEN LOWER(COALESCE(risk_level_code, '')) IN ('low','medium','high','undefined') THEN LOWER(risk_level_code) ELSE 'undefined' END"),
            'category_code' => DB::raw("CASE WHEN LOWER(COALESCE(category_code, '')) IN ('contagious_disease','stagnant_water','waste_accumulation','aggressive_animals','undefined') THEN LOWER(category_code) ELSE 'undefined' END"),
            'estimated_duration_code' => DB::raw("CASE WHEN LOWER(COALESCE(estimated_duration_code, '')) IN ('1_day','3_days','1_week','2_weeks','1_month','3_months','6_months','1_year','undefined') THEN LOWER(estimated_duration_code) ELSE 'undefined' END"),
            'narrative_description' => DB::raw("COALESCE(narrative_description, description)")
        ]);
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Este cambio reorganiza la tabla en SQLite. Down no-op por seguridad.
    }

    private function rebuildSqliteHazardReportsTable(): void
    {
        Schema::disableForeignKeyConstraints();

        if (Schema::hasTable('hazard_reports_old')) {
            if (Schema::hasTable('hazard_reports')) {
                Schema::drop('hazard_reports');
            }
        } else {
            DB::statement('ALTER TABLE hazard_reports RENAME TO hazard_reports_old');
        }

        $legacyIndexNames = [
            'hazard_reports_status_synced_at_index',
            'hazard_reports_user_id_index',
            'hazard_reports_incident_latitude_incident_longitude_index',
            'hazard_reports_local_id_index',
            'hazard_reports_remote_id_index',
            'hazard_reports_local_id_unique',
            'hazard_reports_remote_id_unique',
        ];

        foreach ($legacyIndexNames as $indexName) {
            DB::statement("DROP INDEX IF EXISTS {$indexName}");
        }

        Schema::create('hazard_reports', function (Blueprint $table) {
            $table->id();
            $table->decimal('incident_latitude', 10, 8);
            $table->decimal('incident_longitude', 11, 8);
            $table->decimal('impact_radius_meters', 8, 2);
            $table->string('risk_level_code')->default('undefined');
            $table->string('category_code')->default('undefined');
            $table->string('estimated_duration_code')->default('undefined');
            $table->string('description')->nullable();
            $table->string('narrative_description')->nullable();
            $table->timestamp('reported_at')->nullable();
            $table->string('evidence_photo_url')->nullable();
            $table->string('reported_by_username')->default('Anónimo');
            $table->foreignId('user_id')->nullable()->constrained('users')->onDelete('set null');
            $table->enum('status', ['created', 'synced', 'archived'])->default('created');
            $table->string('local_id')->unique()->nullable();
            $table->string('remote_id')->unique()->nullable();
            $table->timestamp('last_modified_at')->useCurrent();
            $table->timestamp('synced_at')->nullable();
            $table->timestamps();

            $table->index(['status', 'synced_at']);
            $table->index(['user_id']);
            $table->index(['incident_latitude', 'incident_longitude']);
            $table->index('local_id');
            $table->index('remote_id');
        });

        DB::statement(<<<'SQL'
INSERT INTO hazard_reports (
    id,
    incident_latitude,
    incident_longitude,
    impact_radius_meters,
    risk_level_code,
    category_code,
    estimated_duration_code,
    description,
    narrative_description,
    reported_at,
    evidence_photo_url,
    reported_by_username,
    user_id,
    status,
    local_id,
    remote_id,
    last_modified_at,
    synced_at,
    created_at,
    updated_at
)
SELECT
    id,
    incident_latitude,
    incident_longitude,
    impact_radius_meters,
    CASE
        WHEN LOWER(COALESCE(risk_level_code, '')) IN ('low', 'medium', 'high', 'undefined') THEN LOWER(risk_level_code)
        ELSE 'undefined'
    END,
    'undefined',
    'undefined',
    description,
    description,
    NULL,
    NULL,
    'Anónimo',
    user_id,
    status,
    local_id,
    remote_id,
    COALESCE(last_modified_at, updated_at, created_at, CURRENT_TIMESTAMP),
    synced_at,
    created_at,
    updated_at
FROM hazard_reports_old
SQL);

        Schema::drop('hazard_reports_old');
        Schema::enableForeignKeyConstraints();
    }
};
