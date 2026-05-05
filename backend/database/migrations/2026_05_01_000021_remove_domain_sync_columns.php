<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $this->dropKnownIndexes('pets', [
            'pets_user_id_local_id_unique',
            'pets_remote_id_unique',
            'pets_user_id_sync_status_index',
            'pets_user_id_local_uuid_unique',
            'pets_local_uuid_index',
        ]);
        $this->dropColumnsIfPresent('pets', [
            'local_id',
            'local_uuid',
            'remote_id',
            'sync_status',
            'last_modified_at',
            'synced_at',
        ]);

        $this->dropKnownIndexes('routes', [
            'routes_user_id_local_id_unique',
            'routes_remote_id_unique',
            'routes_user_id_sync_status_index',
        ]);
        $this->dropColumnsIfPresent('routes', [
            'local_id',
            'remote_id',
            'sync_status',
            'last_modified_at',
            'synced_at',
        ]);

        $this->dropKnownIndexes('hazard_reports', [
            'hazard_reports_local_id_unique',
            'hazard_reports_remote_id_unique',
            'hazard_reports_local_id_index',
            'hazard_reports_remote_id_index',
            'hazard_reports_status_synced_at_index',
            'hazard_reports_user_local_unique',
        ]);
        $this->dropColumnsIfPresent('hazard_reports', [
            'local_id',
            'remote_id',
            'last_modified_at',
            'synced_at',
        ]);

        $this->dropKnownIndexes('lost_pet_reports', [
            'lost_pet_reports_local_id_unique',
            'lost_pet_reports_remote_id_index',
            'lost_pet_reports_last_modified_at_index',
            'lost_pet_reports_pet_id_sync_status_index',
        ]);
        $this->dropColumnsIfPresent('lost_pet_reports', [
            'local_id',
            'remote_id',
            'sync_status',
            'last_modified_at',
            'synced_at',
        ]);

        $this->dropKnownIndexes('found_pet_reports', [
            'found_pet_reports_local_id_unique',
            'found_pet_reports_remote_id_index',
            'found_pet_reports_last_modified_at_index',
            'found_pet_reports_pet_id_sync_status_index',
        ]);
        $this->dropColumnsIfPresent('found_pet_reports', [
            'local_id',
            'remote_id',
            'sync_status',
            'last_modified_at',
            'synced_at',
        ]);

        $this->dropKnownIndexes('generic_reports', [
            'generic_reports_local_id_unique',
            'generic_reports_remote_id_index',
            'generic_reports_last_modified_at_index',
        ]);
        $this->dropColumnsIfPresent('generic_reports', [
            'local_id',
            'remote_id',
            'sync_status',
            'last_modified_at',
            'synced_at',
        ]);
    }

    public function down(): void
    {
        // This migration intentionally removes the local-first sync contract.
    }

    /**
     * @param  array<int, string>  $indexes
     */
    private function dropKnownIndexes(string $table, array $indexes): void
    {
        foreach ($indexes as $index) {
            try {
                Schema::table($table, function (Blueprint $blueprint) use ($index): void {
                    $blueprint->dropIndex($index);
                });
            } catch (Throwable) {
                try {
                    Schema::table($table, function (Blueprint $blueprint) use ($index): void {
                        $blueprint->dropUnique($index);
                    });
                } catch (Throwable) {
                    // Existing installs differ slightly by migration history.
                }
            }
        }
    }

    /**
     * @param  array<int, string>  $columns
     */
    private function dropColumnsIfPresent(string $table, array $columns): void
    {
        $present = array_values(array_filter(
            $columns,
            static fn (string $column): bool => Schema::hasColumn($table, $column),
        ));

        if ($present === []) {
            return;
        }

        Schema::table($table, function (Blueprint $blueprint) use ($present): void {
            $blueprint->dropColumn($present);
        });
    }
};
