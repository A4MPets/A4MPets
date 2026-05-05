<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('found_pet_reports', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('pet_id')->nullable()->constrained('pets')->nullOnDelete();
            $table->foreignId('matched_lost_pet_report_id')->nullable()->constrained('lost_pet_reports')->nullOnDelete();
            $table->string('pet_local_uuid')->nullable()->index();
            $table->string('local_id')->unique();
            $table->string('remote_id')->nullable()->index();
            $table->decimal('latitude', 10, 7);
            $table->decimal('longitude', 10, 7);
            $table->text('details');
            $table->dateTime('found_date');
            $table->string('photo_url')->nullable();
            $table->string('phone')->nullable();
            $table->string('sync_status')->default('synced');
            $table->dateTime('last_modified_at')->nullable()->index();
            $table->dateTime('synced_at')->nullable();
            $table->timestamps();

            $table->index(['pet_id', 'sync_status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('found_pet_reports');
    }
};
