<?php

namespace App\Services\Reports;

use App\Models\FoundPetReport;
use App\Models\LostPetReport;
use App\Models\Pet;
use App\Services\Comments\ReportCommentService;
use App\Services\Concerns\ReportsRemovedLocalSync;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class FoundPetReportService
{
    use ReportsRemovedLocalSync;

    public function __construct(
        private readonly ReportCommentService $reportCommentService
    ) {}

    public function paginate(bool $includeArchived, int $perPage, int $page): LengthAwarePaginator
    {
        return FoundPetReport::query()
            ->with(['pet', 'matchedLostPetReport', 'comments', 'comments.user'])
            ->orderByDesc('updated_at')
            ->paginate($perPage, ['*'], 'page', $page);
    }

    /** @param array<string, mixed> $validated */
    public function store(?int $userId, array $validated): FoundPetReport
    {
        [$pet, $matchedReport] = $this->resolvePetContext($userId, $validated);
        $report = FoundPetReport::create($this->payload($validated, $pet, $matchedReport, ['user_id' => $userId]));

        return $report->refresh()->load(['pet', 'matchedLostPetReport', 'comments', 'comments.user']);
    }

    /** @param array<string, mixed> $validated */
    public function update(FoundPetReport $report, array $validated): FoundPetReport
    {
        [$pet, $matchedReport] = $this->resolvePetContext($report->user_id, $validated);
        $report->update($this->payload($validated, $pet, $matchedReport));

        return $report->refresh()->load(['pet', 'matchedLostPetReport', 'comments', 'comments.user']);
    }

    public function delete(FoundPetReport $report): void
    {
        $report->comments()->delete();
        $report->delete();
    }

    public function canMutate(?int $userId, FoundPetReport $report): bool
    {
        return $userId !== null && (int) $report->user_id === (int) $userId;
    }

    /** @param array<int, array<string, mixed>> $reports */
    public function sync(?int $userId, array $reports): array
    {
        return $this->removedLocalSyncResult($reports);
    }

    /**
     * @param  array<string, mixed>  $data
     * @return array{0: Pet, 1: LostPetReport|null}
     */
    private function resolvePetContext(?int $userId, array $data): array
    {
        $matchedReport = empty($data['matched_lost_pet_report_id'])
            ? null
            : LostPetReport::query()->with('pet')->find($data['matched_lost_pet_report_id']);

        if ($matchedReport?->pet) {
            return [$matchedReport->pet, $matchedReport];
        }

        if (! empty($data['pet_id'])) {
            $pet = $this->petQuery($userId)->where('id', $data['pet_id'])->first();

            if ($pet) {
                return [$pet, $matchedReport];
            }
        }

        return [Pet::create([
            'user_id' => null,
            'name' => null,
            'photo_path' => $data['photo_url'] ?? null,
            'total_walks' => 0,
            'registered_at' => now(),
            'status' => 'normal',
            'is_ownerless' => true,
        ]), null];
    }

    private function petQuery(?int $userId)
    {
        $query = Pet::query();

        return $userId === null
            ? $query
            : $query->where(fn ($owner) => $owner->where('user_id', $userId)->orWhere(fn ($q) => $q->whereNull('user_id')->where('is_ownerless', true)));
    }

    /**
     * @param  array<string, mixed>  $data
     * @param  array<string, mixed>  $extra
     * @return array<string, mixed>
     */
    private function payload(array $data, Pet $pet, ?LostPetReport $matchedReport, array $extra = []): array
    {
        return $extra + [
            'pet_id' => $pet->id,
            'matched_lost_pet_report_id' => $matchedReport?->id,
            'pet_local_uuid' => $pet->local_uuid ?? null,
            'latitude' => $data['latitude'],
            'longitude' => $data['longitude'],
            'details' => $data['details'],
            'found_date' => $data['found_date'],
            'photo_url' => $data['photo_url'] ?? null,
            'phone' => $data['phone'] ?? null,
        ];
    }
}
