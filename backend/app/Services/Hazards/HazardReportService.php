<?php

namespace App\Services\Hazards;

use App\Models\HazardReport;
use App\Services\Comments\ReportCommentService;
use App\Services\Concerns\ReportsRemovedLocalSync;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class HazardReportService
{
    use ReportsRemovedLocalSync;

    private const RELATIONS = ['comments', 'comments.user', 'riskLevel', 'category', 'estimatedDuration'];

    public function __construct(
        private readonly HazardValueNormalizer $normalizer,
        private readonly ReportCommentService $commentSyncService
    ) {}

    /** @param array<string, mixed> $filters */
    public function paginate(array $filters): LengthAwarePaginator
    {
        $query = HazardReport::with(['riskLevel', 'category', 'estimatedDuration']);

        if (isset($filters['latitude'], $filters['longitude'])) {
            $query->nearby((float) $filters['latitude'], (float) $filters['longitude'], (float) ($filters['radius_km'] ?? 5));
        }

        if (! empty($filters['risk_level'])) {
            $query->byRiskLevel((string) $filters['risk_level']);
        }

        if (empty($filters['include_archived'])) {
            $query->where('status', '!=', 'archived');
        }

        return $query
            ->orderByDesc('updated_at')
            ->paginate(min((int) ($filters['per_page'] ?? 50), 100), ['*'], 'page', (int) ($filters['page'] ?? 1));
    }

    /** @param array<string, mixed> $validated */
    public function store(array $validated, ?int $userId, ?string $fallbackUsername): HazardReport
    {
        $comments = (array) ($validated['comments'] ?? []);
        unset($validated['comments']);

        $hazard = HazardReport::create($this->payload($validated, [
            'reported_by_username' => $validated['reported_by_username'] ?? $fallbackUsername ?? 'Anonimo',
            'status' => 'created',
            'user_id' => $userId,
        ]));

        if ($comments !== []) {
            $this->commentSyncService->syncComments($hazard, $comments);
        }

        return $hazard->load(self::RELATIONS);
    }

    public function canMutate(?int $userId, HazardReport $hazardReport): bool
    {
        return $userId !== null && (int) $hazardReport->user_id === (int) $userId;
    }

    public function canDelete(?int $userId, ?HazardReport $hazardReport = null): bool
    {
        return $userId !== null && ($hazardReport === null || $hazardReport->user_id === null || (int) $hazardReport->user_id === (int) $userId);
    }

    /** @param array<string, mixed> $validated */
    public function update(HazardReport $hazardReport, array $validated): array
    {
        $comments = (array) ($validated['comments'] ?? []);
        unset($validated['comments']);

        $hazardReport->update($this->payload($validated, partial: true));

        if ($comments !== []) {
            $this->commentSyncService->syncComments($hazardReport, $comments);
        }

        return ['conflict' => false, 'hazard' => $hazardReport->load(self::RELATIONS)];
    }

    public function delete(HazardReport $hazardReport): void
    {
        $hazardReport->comments()->delete();
        $hazardReport->delete();
    }

    public function unsynced()
    {
        return HazardReport::query()->where('status', 'created')->get();
    }

    /** @param array<int, array<string, mixed>> $hazards */
    public function sync(array $hazards, ?int $userId): array
    {
        return $this->removedLocalSyncResult($hazards, withDeleted: false, withConflicts: true);
    }

    /**
     * @param  array<string, mixed>  $data
     * @param  array<string, mixed>  $extra
     * @return array<string, mixed>
     */
    private function payload(array $data, array $extra = [], bool $partial = false): array
    {
        $payload = $extra;

        foreach ([
            'risk_level_code' => 'normalizeRiskCode',
            'category_code' => 'normalizeCategoryCode',
            'estimated_duration_code' => 'normalizeDurationCode',
        ] as $key => $normalizer) {
            if (! $partial || array_key_exists($key, $data)) {
                $payload[$key] = $this->normalizer->{$normalizer}($data[$key] ?? null);
            }
        }

        foreach ($data as $key => $value) {
            if (! in_array($key, ['risk_level_code', 'category_code', 'estimated_duration_code'], true)) {
                $payload[$key] = $value;
            }
        }

        if (array_key_exists('narrative_description', $payload) && ! array_key_exists('description', $payload)) {
            $payload['description'] = $payload['narrative_description'];
        }

        if (array_key_exists('description', $payload) && ! array_key_exists('narrative_description', $payload)) {
            $payload['narrative_description'] = $payload['description'];
        }

        return $payload;
    }
}
