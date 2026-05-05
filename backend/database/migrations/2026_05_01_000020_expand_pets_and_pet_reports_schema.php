<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('pets', function (Blueprint $table): void {
            if (! Schema::hasColumn('pets', 'local_uuid')) {
                $table->string('local_uuid')->nullable()->after('local_id');
            }
            if (! Schema::hasColumn('pets', 'total_walks')) {
                $table->unsignedInteger('total_walks')->default(0)->after('photo_path');
            }
            if (! Schema::hasColumn('pets', 'registered_at')) {
                $table->dateTime('registered_at')->nullable()->after('total_walks');
            }
            if (! Schema::hasColumn('pets', 'adoption_date')) {
                $table->dateTime('adoption_date')->nullable()->after('registered_at');
            }
            if (! Schema::hasColumn('pets', 'birth_date')) {
                $table->dateTime('birth_date')->nullable()->after('adoption_date');
            }
            if (! Schema::hasColumn('pets', 'status')) {
                $table->string('status')->default('normal')->after('birth_date');
            }
            if (! Schema::hasColumn('pets', 'is_ownerless')) {
                $table->boolean('is_ownerless')->default(false)->after('status');
            }
        });

        DB::table('pets')->whereNull('local_uuid')->update(['local_uuid' => DB::raw('local_id')]);
        DB::table('pets')->whereNull('registered_at')->update(['registered_at' => DB::raw('created_at')]);
        DB::table('pets')->whereNull('total_walks')->update(['total_walks' => 0]);
        DB::table('pets')->whereNull('status')->update(['status' => 'normal']);

        Schema::table('lost_pet_reports', function (Blueprint $table): void {
            if (! Schema::hasColumn('lost_pet_reports', 'pet_id')) {
                $table->foreignId('pet_id')->nullable()->after('user_id')->constrained('pets')->nullOnDelete();
            }
            if (! Schema::hasColumn('lost_pet_reports', 'pet_local_uuid')) {
                $table->string('pet_local_uuid')->nullable()->after('pet_id')->index();
            }
        });

        Schema::table('found_pet_reports', function (Blueprint $table): void {
            if (! Schema::hasColumn('found_pet_reports', 'pet_id')) {
                $table->foreignId('pet_id')->nullable()->after('user_id')->constrained('pets')->nullOnDelete();
            }
            if (! Schema::hasColumn('found_pet_reports', 'matched_lost_pet_report_id')) {
                $table->foreignId('matched_lost_pet_report_id')->nullable()->after('pet_id')->constrained('lost_pet_reports')->nullOnDelete();
            }
            if (! Schema::hasColumn('found_pet_reports', 'pet_local_uuid')) {
                $table->string('pet_local_uuid')->nullable()->after('matched_lost_pet_report_id')->index();
            }
        });
    }

    public function down(): void
    {
        Schema::table('found_pet_reports', function (Blueprint $table): void {
            if (Schema::hasColumn('found_pet_reports', 'matched_lost_pet_report_id')) {
                $table->dropConstrainedForeignId('matched_lost_pet_report_id');
            }
            if (Schema::hasColumn('found_pet_reports', 'pet_id')) {
                $table->dropConstrainedForeignId('pet_id');
            }
            if (Schema::hasColumn('found_pet_reports', 'pet_local_uuid')) {
                $table->dropColumn('pet_local_uuid');
            }
        });

        Schema::table('lost_pet_reports', function (Blueprint $table): void {
            if (Schema::hasColumn('lost_pet_reports', 'pet_id')) {
                $table->dropConstrainedForeignId('pet_id');
            }
            if (Schema::hasColumn('lost_pet_reports', 'pet_local_uuid')) {
                $table->dropColumn('pet_local_uuid');
            }
        });

        Schema::table('pets', function (Blueprint $table): void {
            foreach (['local_uuid', 'total_walks', 'registered_at', 'adoption_date', 'birth_date', 'status', 'is_ownerless'] as $column) {
                if (Schema::hasColumn('pets', $column)) {
                    $table->dropColumn($column);
                }
            }
        });
    }
};
