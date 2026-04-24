<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('hazard_reports', function (Blueprint $table) {
            try {
                $table->dropUnique('hazard_reports_user_local_unique');
            } catch (\Throwable $e) {
                // Keep migration idempotent across SQLite/MySQL setups.
            }
        });

        Schema::table('hazard_reports', function (Blueprint $table) {
            try {
                $table->unique('local_id', 'hazard_reports_local_id_unique');
            } catch (\Throwable $e) {
                // Keep migration idempotent across SQLite/MySQL setups.
            }
        });
    }

    public function down(): void
    {
        Schema::table('hazard_reports', function (Blueprint $table) {
            try {
                $table->dropUnique('hazard_reports_local_id_unique');
            } catch (\Throwable $e) {
            }
        });

        Schema::table('hazard_reports', function (Blueprint $table) {
            try {
                $table->unique(['user_id', 'local_id'], 'hazard_reports_user_local_unique');
            } catch (\Throwable $e) {
            }
        });
    }
};
