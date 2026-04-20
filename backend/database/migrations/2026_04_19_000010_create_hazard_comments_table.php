<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('hazard_comments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('hazard_report_id')->constrained('hazard_reports')->cascadeOnDelete();
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('author_name');
            $table->string('author_avatar_url')->nullable();
            $table->boolean('is_anonymous')->default(false);
            $table->text('comment_text');
            $table->timestamp('commented_at')->nullable();
            $table->string('content_hash', 64);
            $table->timestamp('last_modified_at')->useCurrent();
            $table->timestamp('synced_at')->nullable();
            $table->timestamps();

            $table->unique(['hazard_report_id', 'content_hash']);
            $table->index(['hazard_report_id', 'created_at']);
            $table->index(['hazard_report_id', 'synced_at']);
            $table->index(['user_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('hazard_comments');
    }
};