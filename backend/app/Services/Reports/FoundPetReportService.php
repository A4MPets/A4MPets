<?php

namespace App\Services\Reports;

use App\Models\FoundPetReport;
use App\Models\LostPetReport;
use App\Models\Pet;
use App\Services\Comments\ReportCommentService;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Throwable;

class FoundPetReportService
{
    public function __construct(
        private readonly ReportCommentService $reportCommentService
    ) {}

    public function paginate(bool $includeArchived, int $perPage, int $page): LengthAwarePaginator
    {
        $query = FoundPetReport::query()->with(['pet', 'matchedLostPetReport', 'comments', 'comments.user']);

        return $query
            ->orderByDesc('updated_at')
            ->paginate($perPage, ['*'], 'page', $page);
    }

    /**
     * @param  array<string, mixed>  $validated
     */
    public function store(?int $userId, array $validated): FoundPetReport
    {
        [$pet, $matchedReport] = $this->resolvePetContext($userId, $validated);
        $report = FoundPetReport::create([
            'user_id' => $userId,
            'pet_id' => $pet->id,
            'matched_lost_pet_report_id' => $matchedReport?->id,
            'pet_local_uuid' => $pet->local_uuid ?? null,
            'latitude' => $validated['latitude'],
            'longitude' => $validated['longitude'],
            'details' => $validated['details'],
            'found_date' => $validated['found_date'],
            'photo_url' => $validated['photo_url'] ?? null,
            'phone' => $validated['phone'] ?? null,
        ]);

        return $report->refresh()->load(['pet', 'matchedLostPetReport', 'comments', 'comments.user']);
    }

    /**
     * @param  array<string, mixed>  $validated
     */
    public function update(FoundPetReport $report, array $validated): FoundPetReport
    {
        [$pet, $matchedReport] = $this->resolvePetContext($report->user_id, $validated);
        $report->update([
            'pet_id' => $pet->id,
            'matched_lost_pet_report_id' => $matchedReport?->id,
            'pet_local_uuid' => $pet->local_uuid ?? null,
            'latitude' => $validated['latitude'],
            'longitude' => $validated['longitude'],
            'details' => $validated['details'],
            'found_date' => $validated['found_date'],
            'photo_url' => $validated['photo_url'] ?? null,
            'phone' => $validated['phone'] ?? null,
        ]);

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

    /**
     * @param  array<int, array<string, mixed>>  $reports
     * @return array<string, mixed>
     */
    public function sync(?int $userId, array $reports): array
    {
        $results = [
            'synced' => 0,
            'deleted' => 0,
            'errors' => 0,
            'details' => [],
        ];

        foreach ($reports as $reportData) {
            try {
                $report = FoundPetReport::query()
                    ->where(function ($query) use ($reportData): void {
                        if (! empty($reportData['remote_id'])) {
                            $query->where('remote_id', $reportData['remote_id'])
                                ->orWhere('id', $reportData['remote_id']);
                        }

                        $query->orWhere('local_id', $reportData['local_id']);
                    })
                    ->first();

                if (($reportData['sync_status'] ?? 'created') === 'deleted') {
                    if ($report) {
                        $report->update([
                            'sync_status' => 'deleted',
                            'last_modified_at' => $reportData['last_modified_at'],
                            'synced_at' => now(),
                        ]);
                    }

                    $results['deleted']++;

                    continue;
                }

                [$pet, $matchedReport] = $this->resolvePetContext($userId, $reportData, $reportData['local_id']);

                $payload = [
                    'user_id' => $userId,
                    'pet_id' => $pet->id,
                    'matched_lost_pet_report_id' => $matchedReport?->id,
                    'pet_local_uuid' => $pet->local_uuid ?? $pet->local_id,
                    'latitude' => $reportData['latitude'],
                    'longitude' => $reportData['longitude'],
                    'details' => $reportData['details'],
                    'found_date' => $reportData['found_date'],
                    'photo_url' => $reportData['photo_url'] ?? null,
                    'phone' => $reportData['phone'] ?? null,
                    'sync_status' => 'synced',
                    'last_modified_at' => $reportData['last_modified_at'],
                    'synced_at' => now(),
                ];

                if ($report) {
                    $report->update($payload);
                } else {
                    $payload['local_id'] = $reportData['local_id'];
                    $report = FoundPetReport::create($payload);
                }

                $this->ensureRemoteId($report);
                $this->reportCommentService->syncComments($report, (array) ($reportData['comments'] ?? []));
                $results['synced']++;
                $results['details'][] = [
                    'local_id' => $reportData['local_id'],
                    'remote_id' => $report->remote_id,
                    'status' => 'synced',
                ];
            } catch (Throwable $error) {
                $results['errors']++;
                $results['details'][] = [
                    'local_id' => $reportData['local_id'] ?? 'unknown',
                    'status' => 'error',
                    'error' => $error->getMessage(),
                ];
            }
        }

        return $results;
    }

    private function ensureRemoteId(FoundPetReport $report): void
    {
        $report->update([
            'remote_id' => $report->remote_id ?? (string) $report->id,
        ]);
    }

    /**
     * @param  array<string, mixed>  $data
     * @return array{0: Pet, 1: LostPetReport|null}
     */
    private function resolvePetContext(?int $userId, array $data, ?string $fallbackLocalId = null): array
    {
        $matchedReport = null;
        if (! empty($data['matched_lost_pet_report_id'])) {
            $matchedReport = LostPetReport::query()
                ->with('pet')
                ->where('id', $data['matched_lost_pet_report_id'])
                ->first();
        }

        if ($matchedReport?->pet) {
            return [$matchedReport->pet, $matchedReport];
        }

        if (! empty($data['pet_id'])) {
            $petQuery = Pet::query()->where('id', $data['pet_id']);

            if ($userId !== null) {
                $petQuery->where(function ($query) use ($userId): void {
                    $query->where('user_id', $userId)
                        ->orWhere(function ($ownerlessQuery): void {
                            $ownerlessQuery->whereNull('user_id')
                                ->where('is_ownerless', true);
                        });
                });
            }

            $pet = $petQuery->first();

            if ($pet) {
                return [$pet, $matchedReport];
            }
        }

        $pet = Pet::create([
            'user_id' => null,
            'name' => null,
            'photo_path' => $data['photo_url'] ?? null,
            'total_walks' => 0,
            'registered_at' => now(),
            'status' => 'normal',
            'is_ownerless' => true,
        ]);

        return [$pet, null];
    }
}
