<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('lost_pet_reports', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->string('local_id')->unique();
            $table->string('remote_id')->nullable()->index();
            $table->decimal('last_seen_latitude', 10, 7);
            $table->decimal('last_seen_longitude', 10, 7);
            $table->string('name');
            $table->text('details');
            $table->dateTime('disappearance_date');
            $table->string('photo_url')->nullable();
            $table->string('phone')->nullable();
            $table->string('sync_status')->default('synced');
            $table->dateTime('last_modified_at')->nullable()->index();
            $table->dateTime('synced_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('lost_pet_reports');
    }
};
