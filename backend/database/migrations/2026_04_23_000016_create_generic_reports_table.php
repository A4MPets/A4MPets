<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('generic_reports', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->string('local_id')->unique();
            $table->string('remote_id')->nullable()->index();
            $table->decimal('latitude', 10, 7);
            $table->decimal('longitude', 10, 7);
            $table->text('description');
            $table->dateTime('reported_date');
            $table->string('risk_level_code')->default('undefined');
            $table->string('photo_url')->nullable();
            $table->string('sync_status')->default('synced');
            $table->dateTime('last_modified_at')->nullable()->index();
            $table->dateTime('synced_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('generic_reports');
    }
};
