<?php

namespace App\Services\Reports;

use App\Models\LostPetReport;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Throwable;

class LostPetReportService
{
    public function paginate(bool $includeArchived, int $perPage, int $page): LengthAwarePaginator
    {
        $query = LostPetReport::query();

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
        $report = LostPetReport::updateOrCreate(
            ['local_id' => $validated['local_id']],
            [
                'user_id' => $userId,
                'last_seen_latitude' => $validated['last_seen_latitude'],
                'last_seen_longitude' => $validated['last_seen_longitude'],
                'name' => $validated['name'],
                'details' => $validated['details'],
                'disappearance_date' => $validated['disappearance_date'],
                'photo_url' => $validated['photo_url'],
                'phone' => $validated['phone'],
                'sync_status' => 'synced',
                'last_modified_at' => now(),
                'synced_at' => now(),
            ]
        );

        $this->ensureRemoteId($report);

        return $report->refresh();
    }

    /**
     * @param  array<string, mixed>  $validated
     */
    public function update(LostPetReport $report, array $validated): LostPetReport
    {
        $report->update([
            'last_seen_latitude' => $validated['last_seen_latitude'],
            'last_seen_longitude' => $validated['last_seen_longitude'],
            'name' => $validated['name'],
            'details' => $validated['details'],
            'disappearance_date' => $validated['disappearance_date'],
            'photo_url' => $validated['photo_url'],
            'phone' => $validated['phone'],
            'sync_status' => 'synced',
            'last_modified_at' => now(),
            'synced_at' => now(),
        ]);

        return $report->refresh();
    }

    public function delete(LostPetReport $report): void
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
                    }

                    $results['deleted']++;

                    continue;
                }

                $payload = [
                    'user_id' => $userId,
                    'last_seen_latitude' => $reportData['last_seen_latitude'],
                    'last_seen_longitude' => $reportData['last_seen_longitude'],
                    'name' => $reportData['name'],
                    'details' => $reportData['details'],
                    'disappearance_date' => $reportData['disappearance_date'],
                    'photo_url' => $reportData['photo_url'],
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

    private function ensureRemoteId(LostPetReport $report): void
    {
        $report->update([
            'remote_id' => $report->remote_id ?? (string) $report->id,
        ]);
    }
}
