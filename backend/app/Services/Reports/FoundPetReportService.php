<?php

namespace App\Services\Reports;

use App\Models\FoundPetReport;
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
        $query = FoundPetReport::query()->with(['comments', 'comments.user']);

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
    public function store(?int $userId, array $validated): FoundPetReport
    {
        $comments = (array) ($validated['comments'] ?? []);
        $report = FoundPetReport::updateOrCreate(
            ['local_id' => $validated['local_id']],
            [
                'user_id' => $userId,
                'latitude' => $validated['latitude'],
                'longitude' => $validated['longitude'],
                'details' => $validated['details'],
                'found_date' => $validated['found_date'],
                'photo_url' => $validated['photo_url'] ?? null,
                'phone' => $validated['phone'] ?? null,
                'sync_status' => 'synced',
                'last_modified_at' => now(),
                'synced_at' => now(),
            ]
        );

        $this->ensureRemoteId($report);

        if ($comments !== []) {
            $this->reportCommentService->syncComments($report, $comments);
        }

        return $report->refresh()->load(['comments', 'comments.user']);
    }

    /**
     * @param  array<string, mixed>  $validated
     */
    public function update(FoundPetReport $report, array $validated): FoundPetReport
    {
        $comments = (array) ($validated['comments'] ?? []);
        $report->update([
            'latitude' => $validated['latitude'],
            'longitude' => $validated['longitude'],
            'details' => $validated['details'],
            'found_date' => $validated['found_date'],
            'photo_url' => $validated['photo_url'] ?? null,
            'phone' => $validated['phone'] ?? null,
            'sync_status' => 'synced',
            'last_modified_at' => now(),
            'synced_at' => now(),
        ]);

        if ($comments !== []) {
            $this->reportCommentService->syncComments($report, $comments);
        }

        return $report->refresh()->load(['comments', 'comments.user']);
    }

    public function delete(FoundPetReport $report): void
    {
        $report->update([
            'sync_status' => 'deleted',
            'last_modified_at' => now(),
            'synced_at' => now(),
        ]);
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

                $payload = [
                    'user_id' => $userId,
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
}
