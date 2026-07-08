<?php

namespace App\Services\Reports;

use App\Models\GenericReport;
use App\Services\Comments\ReportCommentService;
use App\Services\Concerns\ReportsRemovedLocalSync;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class GenericReportService
{
    use ReportsRemovedLocalSync;

    public function __construct(
        private readonly ReportCommentService $reportCommentService
    ) {}

    public function paginate(bool $includeArchived, int $perPage, int $page): LengthAwarePaginator
    {
        return GenericReport::query()
            ->with(['user', 'comments', 'comments.user'])
            ->orderByDesc('updated_at')
            ->paginate($perPage, ['*'], 'page', $page);
    }

    /** @param array<string, mixed> $validated */
    public function store(?int $userId, array $validated): GenericReport
    {
        $report = GenericReport::create($this->payload($validated, ['user_id' => $userId]));

        return $report->refresh()->load(['user', 'comments', 'comments.user']);
    }

    /** @param array<string, mixed> $validated */
    public function update(GenericReport $report, array $validated): GenericReport
    {
        $report->update($this->payload($validated));

        return $report->refresh()->load(['user', 'comments', 'comments.user']);
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

    /** @param array<int, array<string, mixed>> $reports */
    public function sync(?int $userId, array $reports): array
    {
        return $this->removedLocalSyncResult($reports);
    }

    /**
     * @param  array<string, mixed>  $data
     * @param  array<string, mixed>  $extra
     * @return array<string, mixed>
     */
    private function payload(array $data, array $extra = []): array
    {
        return $extra + [
            'latitude' => $data['latitude'],
            'longitude' => $data['longitude'],
            'description' => $data['description'],
            'reported_date' => $data['reported_date'],
            'risk_level_code' => $this->normalizeRiskCode($data['risk_level_code']),
            'impact_radius_meters' => max(0, (int) round((float) ($data['impact_radius_meters'] ?? 0))),
            'photo_url' => $data['photo_url'] ?? null,
        ];
    }

    private function normalizeRiskCode(?string $value): string
    {
        $normalized = strtolower(trim((string) $value));

        return in_array($normalized, ['low', 'medium', 'high', 'undefined'], true) ? $normalized : 'undefined';
    }
}
