<?php

use App\Models\HazardReport;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('report_comments', function (Blueprint $table): void {
            $table->id();
            $table->string('commentable_type');
            $table->unsignedBigInteger('commentable_id');
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->string('author_name', 100)->default('Anonimo');
            $table->string('author_avatar_url', 500)->nullable();
            $table->boolean('is_anonymous')->default(true);
            $table->text('comment_text');
            $table->timestamp('commented_at')->nullable();
            $table->string('content_hash', 64);
            $table->timestamp('last_modified_at')->nullable();
            $table->timestamp('synced_at')->nullable();
            $table->timestamps();

            $table->index(['commentable_type', 'commentable_id'], 'report_comments_commentable_index');
            $table->unique(
                ['commentable_type', 'commentable_id', 'content_hash'],
                'report_comments_unique_hash'
            );
        });

        if (! Schema::hasTable('hazard_comments')) {
            return;
        }

        $hazardsById = HazardReport::query()->pluck('id')->flip();
        $legacyComments = DB::table('hazard_comments')->get();
        foreach ($legacyComments as $comment) {
            if (! isset($hazardsById[$comment->hazard_report_id])) {
                continue;
            }

            DB::table('report_comments')->insert([
                'commentable_type' => HazardReport::class,
                'commentable_id' => $comment->hazard_report_id,
                'user_id' => $comment->user_id,
                'author_name' => $comment->author_name ?? 'Anonimo',
                'author_avatar_url' => $comment->author_avatar_url,
                'is_anonymous' => (bool) $comment->is_anonymous,
                'comment_text' => $comment->comment_text,
                'commented_at' => $comment->commented_at,
                'content_hash' => $comment->content_hash,
                'last_modified_at' => $comment->last_modified_at,
                'synced_at' => $comment->synced_at,
                'created_at' => $comment->created_at ?? now(),
                'updated_at' => $comment->updated_at ?? now(),
            ]);
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('report_comments');
    }
};
