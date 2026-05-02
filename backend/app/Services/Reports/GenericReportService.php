<?php

namespace App\Services\Reports;

use App\Models\GenericReport;
use App\Services\Comments\ReportCommentService;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Throwable;

class GenericReportService
{
    public function __construct(
        private readonly ReportCommentService $reportCommentService
    ) {}

    public function paginate(bool $includeArchived, int $perPage, int $page): LengthAwarePaginator
    {
        $query = GenericReport::query()->with(['comments', 'comments.user']);

        return $query
            ->orderByDesc('updated_at')
            ->paginate($perPage, ['*'], 'page', $page);
    }

    /**
     * @param  array<string, mixed>  $validated
     */
    public function store(?int $userId, array $validated): GenericReport
    {
        $report = GenericReport::create([
            'user_id' => $userId,
            'latitude' => $validated['latitude'],
            'longitude' => $validated['longitude'],
            'description' => $validated['description'],
            'reported_date' => $validated['reported_date'],
            'risk_level_code' => $this->normalizeRiskCode($validated['risk_level_code']),
            'impact_radius_meters' => $this->normalizeImpactRadiusMeters($validated['impact_radius_meters'] ?? 0),
            'photo_url' => $validated['photo_url'] ?? null,
        ]);

        return $report->refresh()->load(['comments', 'comments.user']);
    }

    /**
     * @param  array<string, mixed>  $validated
     */
    public function update(GenericReport $report, array $validated): GenericReport
    {
        $report->update([
            'latitude' => $validated['latitude'],
            'longitude' => $validated['longitude'],
            'description' => $validated['description'],
            'reported_date' => $validated['reported_date'],
            'risk_level_code' => $this->normalizeRiskCode($validated['risk_level_code']),
            'impact_radius_meters' => $this->normalizeImpactRadiusMeters($validated['impact_radius_meters'] ?? 0),
            'photo_url' => $validated['photo_url'] ?? null,
        ]);

        return $report->refresh()->load(['comments', 'comments.user']);
    }

    public function delete(GenericReport $report): void
    {
        $report->comments()->delete();
        $report->delete();
    }

    public function canMutate(?int $userId, GenericReport $report): bool
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
                $report = GenericReport::query()
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
                    'description' => $reportData['description'],
                    'reported_date' => $reportData['reported_date'],
                    'risk_level_code' => $this->normalizeRiskCode($reportData['risk_level_code']),
                    'impact_radius_meters' => $this->normalizeImpactRadiusMeters($reportData['impact_radius_meters'] ?? 0),
                    'photo_url' => $reportData['photo_url'] ?? null,
                    'sync_status' => 'synced',
                    'last_modified_at' => $reportData['last_modified_at'],
                    'synced_at' => now(),
                ];

                if ($report) {
                    $report->update($payload);
                } else {
                    $payload['local_id'] = $reportData['local_id'];
                    $report = GenericReport::create($payload);
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

    private function ensureRemoteId(GenericReport $report): void
    {
        $report->update([
            'remote_id' => $report->remote_id ?? (string) $report->id,
        ]);
    }

    private function normalizeRiskCode(?string $value): string
    {
        $normalized = strtolower(trim((string) $value));

        if (in_array($normalized, ['low', 'medium', 'high', 'undefined'], true)) {
            return $normalized;
        }

        return 'undefined';
    }

    private function normalizeImpactRadiusMeters(mixed $value): int
    {
        return max(0, (int) round((float) $value));
    }
}
