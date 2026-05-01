<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('pets', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('local_id');
            $table->string('local_uuid')->nullable();
            $table->string('remote_id')->nullable();
            $table->string('name')->nullable();
            $table->string('photo_path')->nullable();
            $table->unsignedInteger('total_walks')->default(0);
            $table->dateTime('registered_at')->nullable();
            $table->dateTime('adoption_date')->nullable();
            $table->dateTime('birth_date')->nullable();
            $table->enum('status', ['normal', 'perdida'])->default('normal');
            $table->boolean('is_ownerless')->default(false);
            $table->enum('sync_status', ['created', 'synced', 'deleted'])->default('created');
            $table->timestamp('last_modified_at')->useCurrent();
            $table->timestamp('synced_at')->nullable();
            $table->timestamps();

            $table->unique(['user_id', 'local_id']);
            $table->unique(['user_id', 'local_uuid']);
            $table->unique('remote_id');
            $table->index(['user_id', 'sync_status']);
            $table->index(['user_id', 'status']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pets');
    }
};
