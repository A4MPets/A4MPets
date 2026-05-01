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

        if (! $includeArchived) {
            $query->where('sync_status', '!=', 'deleted');
        }

        return $query
            ->orderByDesc('last_modified_at')
            ->paginate($perPage, ['*'], 'page', $page);
    }

    /**
     * @param  array<string, mixed>  $validated
     */
    public function store(?int $userId, array $validated): LostPetReport
    {
        $comments = (array) ($validated['comments'] ?? []);
        $pet = $this->resolvePetForUser($userId, $validated['pet_local_uuid']);
        $this->ensureNoActiveReportForPet($pet, $validated['local_id']);

        $report = LostPetReport::updateOrCreate(
            ['local_id' => $validated['local_id']],
            [
                'user_id' => $userId,
                'pet_id' => $pet->id,
                'pet_local_uuid' => $pet->local_uuid ?? $pet->local_id,
                'last_seen_latitude' => $validated['last_seen_latitude'],
                'last_seen_longitude' => $validated['last_seen_longitude'],
                'name' => null,
                'details' => $validated['details'],
                'disappearance_date' => $validated['disappearance_date'],
                'photo_url' => $validated['photo_url'] ?? $pet->photo_path,
                'phone' => $validated['phone'],
                'sync_status' => 'synced',
                'last_modified_at' => now(),
                'synced_at' => now(),
            ]
        );

        $this->ensureRemoteId($report);
        $pet->update([
            'status' => 'perdida',
            'sync_status' => 'synced',
            'last_modified_at' => now(),
            'synced_at' => now(),
        ]);

        if ($comments !== []) {
            $this->reportCommentService->syncComments($report, $comments);
        }

        return $report->refresh()->load(['pet', 'comments', 'comments.user']);
    }

    /**
     * @param  array<string, mixed>  $validated
     */
    public function update(LostPetReport $report, array $validated): LostPetReport
    {
        $comments = (array) ($validated['comments'] ?? []);
        $pet = $this->resolvePetForUser($report->user_id, $validated['pet_local_uuid']);
        $this->ensureNoActiveReportForPet($pet, $report->local_id);
        $report->update([
            'pet_id' => $pet->id,
            'pet_local_uuid' => $pet->local_uuid ?? $pet->local_id,
            'last_seen_latitude' => $validated['last_seen_latitude'],
            'last_seen_longitude' => $validated['last_seen_longitude'],
            'name' => null,
            'details' => $validated['details'],
            'disappearance_date' => $validated['disappearance_date'],
            'photo_url' => $validated['photo_url'] ?? $pet->photo_path,
            'phone' => $validated['phone'],
            'sync_status' => 'synced',
            'last_modified_at' => now(),
            'synced_at' => now(),
        ]);

        if ($comments !== []) {
            $this->reportCommentService->syncComments($report, $comments);
        }

        $pet->update([
            'status' => 'perdida',
            'sync_status' => 'synced',
            'last_modified_at' => now(),
            'synced_at' => now(),
        ]);

        return $report->refresh()->load(['pet', 'comments', 'comments.user']);
    }

    public function delete(LostPetReport $report): void
    {
        $report->update([
            'sync_status' => 'deleted',
            'last_modified_at' => now(),
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

    private function resolvePetForUser(?int $userId, string $localUuid, ?string $remoteId = null): Pet
    {
        return Pet::query()
            ->where(function ($query) use ($userId): void {
                $userId ? $query->where('user_id', $userId) : $query->whereNull('user_id');
            })
            ->where('sync_status', '!=', 'deleted')
            ->where(function ($query) use ($localUuid, $remoteId): void {
                $query->where('local_uuid', $localUuid)
                    ->orWhere('local_id', $localUuid)
                    ->orWhere('remote_id', $localUuid);
                if ($remoteId !== null && $remoteId !== '') {
                    $query->orWhere('remote_id', $remoteId)
                        ->orWhere('id', $remoteId);
                }
            })
            ->firstOrFail();
    }

    private function ensureNoActiveReportForPet(Pet $pet, string $currentLocalId): void
    {
        $exists = LostPetReport::query()
            ->where('pet_id', $pet->id)
            ->where('local_id', '!=', $currentLocalId)
            ->where('sync_status', '!=', 'deleted')
            ->exists();

        abort_if($exists, 422, 'La mascota ya tiene un reporte de perdida activo.');
    }
}
