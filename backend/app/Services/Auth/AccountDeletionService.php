<?php

namespace App\Services\Auth;

use App\Models\FoundPetReport;
use App\Models\GenericReport;
use App\Models\HazardComment;
use App\Models\HazardReport;
use App\Models\LostPetReport;
use App\Models\ReportComment;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class AccountDeletionService
{
    /**
     * Delete private account data and anonymize community records.
     */
    public function deleteAccount(User $user): void
    {
        DB::transaction(function () use ($user): void {
            $mediaUrls = $this->collectMediaUrls($user);

            $this->anonymizeCommunityReports($user);
            $this->anonymizeComments($user);

            $user->apiTokens()->delete();
            $user->routes()->delete();
            $user->pets()->delete();
            $user->delete();

            $this->deleteInternalMedia($mediaUrls);
        });
    }

    /**
     * @return array<int, string>
     */
    private function collectMediaUrls(User $user): array
    {
        $mediaUrls = [];

        if ($user->profile_photo_url) {
            $mediaUrls[] = $user->profile_photo_url;
        }

        $mediaUrls = array_merge(
            $mediaUrls,
            $user->pets()->pluck('photo_path')->filter()->all(),
            HazardReport::query()->where('user_id', $user->id)->pluck('evidence_photo_url')->filter()->all(),
            LostPetReport::query()->where('user_id', $user->id)->pluck('photo_url')->filter()->all(),
            FoundPetReport::query()->where('user_id', $user->id)->pluck('photo_url')->filter()->all(),
            GenericReport::query()->where('user_id', $user->id)->pluck('photo_url')->filter()->all()
        );

        return array_values(array_unique(array_filter($mediaUrls)));
    }

    private function anonymizeCommunityReports(User $user): void
    {
        HazardReport::query()
            ->where('user_id', $user->id)
            ->update([
                'user_id' => null,
                'reported_by_username' => 'Usuario eliminado',
                'evidence_photo_url' => null,
                'updated_at' => now(),
            ]);

        LostPetReport::query()
            ->where('user_id', $user->id)
            ->update([
                'user_id' => null,
                'pet_id' => null,
                'name' => 'Mascota reportada',
                'photo_url' => null,
                'phone' => null,
                'updated_at' => now(),
            ]);

        FoundPetReport::query()
            ->where('user_id', $user->id)
            ->update([
                'user_id' => null,
                'pet_id' => null,
                'photo_url' => null,
                'phone' => null,
                'updated_at' => now(),
            ]);

        GenericReport::query()
            ->where('user_id', $user->id)
            ->update([
                'user_id' => null,
                'photo_url' => null,
                'updated_at' => now(),
            ]);
    }

    private function anonymizeComments(User $user): void
    {
        ReportComment::query()
            ->where('user_id', $user->id)
            ->get()
            ->each(function (ReportComment $comment): void {
                $comment->fill([
                    'user_id' => null,
                    'author_name' => 'Usuario eliminado',
                    'author_avatar_url' => null,
                    'is_anonymous' => true,
                    'last_modified_at' => now(),
                ]);
                $comment->content_hash = ReportComment::makeContentHash($comment->getAttributes());
                $comment->save();
            });

        HazardComment::query()
            ->where('user_id', $user->id)
            ->get()
            ->each(function (HazardComment $comment): void {
                $comment->fill([
                    'user_id' => null,
                    'author_name' => 'Usuario eliminado',
                    'author_avatar_url' => null,
                    'is_anonymous' => true,
                    'last_modified_at' => now(),
                ]);
                $comment->content_hash = HazardComment::makeContentHash($comment->getAttributes());
                $comment->save();
            });
    }

    /**
     * @param  array<int, string>  $mediaUrls
     */
    private function deleteInternalMedia(array $mediaUrls): void
    {
        foreach ($mediaUrls as $mediaUrl) {
            $path = $this->mediaPathFromUrl($mediaUrl);
            if ($path !== null) {
                Storage::disk('local')->delete($path);
            }
        }
    }

    private function mediaPathFromUrl(string $mediaUrl): ?string
    {
        $path = parse_url($mediaUrl, PHP_URL_PATH);
        if (! is_string($path)) {
            return null;
        }

        if (! preg_match('#/api/media/([A-Za-z0-9_-]+)/([A-Za-z0-9._-]+)$#', $path, $matches)) {
            return null;
        }

        $bucket = $matches[1];
        $fileName = $matches[2];
        if (! in_array($bucket, ['pets', 'hazards', 'profiles', 'lost_pets', 'found_pets', 'generic_reports'], true)) {
            return null;
        }

        return 'media/'.$bucket.'/'.$fileName;
    }
}
