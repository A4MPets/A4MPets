<?php

namespace App\Services\Reports;

use App\Models\LostPetReport;
use App\Models\Pet;
use App\Services\Comments\ReportCommentService;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Throwable;

class LostPetReportService
{
    public function __construct(
        private readonly ReportCommentService $reportCommentService
    ) {}

    public function paginate(bool $includeArchived, int $perPage, int $page): LengthAwarePaginator
    {
        $query = LostPetReport::query()->with(['pet', 'comments', 'comments.user']);

        return $query
            ->orderByDesc('updated_at')
            ->paginate($perPage, ['*'], 'page', $page);
    }

    /**
     * @param  array<string, mixed>  $validated
     */
    public function store(?int $userId, array $validated): LostPetReport
    {
        $pet = $this->resolvePetForUser($userId, (int) $validated['pet_id']);
        $this->ensureNoActiveReportForPet($pet);

        $report = LostPetReport::create([
            'user_id' => $userId,
            'pet_id' => $pet->id,
            'pet_local_uuid' => $pet->local_uuid ?? null,
            'last_seen_latitude' => $validated['last_seen_latitude'],
            'last_seen_longitude' => $validated['last_seen_longitude'],
            'name' => null,
            'details' => $validated['details'],
            'disappearance_date' => $validated['disappearance_date'],
            'photo_url' => $validated['photo_url'] ?? null,
            'phone' => $validated['phone'],
        ]);

        $pet->update([
            'status' => 'perdida',
        ]);

        return $report->refresh()->load(['pet', 'comments', 'comments.user']);
    }

    /**
     * @param  array<string, mixed>  $validated
     */
    public function update(LostPetReport $report, array $validated): LostPetReport
    {
        $pet = $this->resolvePetForUser($report->user_id, (int) $validated['pet_id']);
        $this->ensureNoActiveReportForPet($pet, $report);
        $report->update([
            'pet_id' => $pet->id,
            'pet_local_uuid' => $pet->local_uuid ?? null,
            'last_seen_latitude' => $validated['last_seen_latitude'],
            'last_seen_longitude' => $validated['last_seen_longitude'],
            'name' => null,
            'details' => $validated['details'],
            'disappearance_date' => $validated['disappearance_date'],
            'photo_url' => $validated['photo_url'] ?? null,
            'phone' => $validated['phone'],
        ]);

        $pet->update([
            'status' => 'perdida',
        ]);

        return $report->refresh()->load(['pet', 'comments', 'comments.user']);
    }

    public function delete(LostPetReport $report): void
    {
        if ($report->pet) {
            $report->pet->update([
                'status' => 'normal',
            ]);
        }

        $report->comments()->delete();
        $report->delete();
    }

    public function canMutate(?int $userId, LostPetReport $report): bool
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
                $report = LostPetReport::query()
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
                        if ($report->pet) {
                            $report->pet->update([
                                'status' => 'normal',
                                'sync_status' => 'synced',
                                'last_modified_at' => now(),
                                'synced_at' => now(),
                            ]);
                        }
                    }

                    $results['deleted']++;

                    continue;
                }

                $pet = $this->resolvePetForUser(
                    $userId,
                    $reportData['pet_local_uuid'],
                    $reportData['pet_remote_id'] ?? null,
                );
                $this->ensureNoActiveReportForPet($pet, $reportData['local_id']);

                $payload = [
                    'user_id' => $userId,
                    'pet_id' => $pet->id,
                    'pet_local_uuid' => $pet->local_uuid ?? $pet->local_id,
                    'last_seen_latitude' => $reportData['last_seen_latitude'],
                    'last_seen_longitude' => $reportData['last_seen_longitude'],
                    'name' => null,
                    'details' => $reportData['details'],
                    'disappearance_date' => $reportData['disappearance_date'],
                    'photo_url' => $reportData['photo_url'] ?? $pet->photo_path,
                    'phone' => $reportData['phone'],
                    'sync_status' => 'synced',
                    'last_modified_at' => $reportData['last_modified_at'],
                    'synced_at' => now(),
                ];

                if ($report) {
                    $report->update($payload);
                } else {
                    $payload['local_id'] = $reportData['local_id'];
                    $report = LostPetReport::create($payload);
                }

                $this->ensureRemoteId($report);
                $pet->update([
                    'status' => 'perdida',
                    'sync_status' => 'synced',
                    'last_modified_at' => now(),
                    'synced_at' => now(),
                ]);
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

    private function ensureRemoteId(LostPetReport $report): void
    {
        $report->update([
            'remote_id' => $report->remote_id ?? (string) $report->id,
        ]);
    }

    private function resolvePetForUser(?int $userId, int $petId): Pet
    {
        return Pet::query()
            ->where('user_id', $userId)
            ->where('id', $petId)
            ->firstOrFail();
    }

    private function ensureNoActiveReportForPet(Pet $pet, ?LostPetReport $currentReport = null): void
    {
        $query = LostPetReport::query()->where('pet_id', $pet->id);

        if ($currentReport !== null) {
            $query->where('id', '!=', $currentReport->id);
        }

        $exists = $query->exists();

        abort_if($exists, 422, 'La mascota ya tiene un reporte de perdida activo.');
    }
}
