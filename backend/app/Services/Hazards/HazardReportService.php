<?php

namespace App\Services\Hazards;

use App\Models\HazardReport;
use App\Services\Comments\ReportCommentService;
use Carbon\Carbon;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Facades\Log;
use Throwable;

class HazardReportService
{
    public function __construct(
        private readonly HazardValueNormalizer $normalizer,
        private readonly ReportCommentService $commentSyncService
    ) {}

    /**
     * @param  array<string, mixed>  $filters
     */
    public function paginate(array $filters): LengthAwarePaginator
    {
        $query = HazardReport::with([
            'comments',
            'comments.user',
            'riskLevel',
            'category',
            'estimatedDuration',
        ]);

        if (isset($filters['latitude'], $filters['longitude'])) {
            $query->nearby(
                (float) $filters['latitude'],
                (float) $filters['longitude'],
                (float) ($filters['radius_km'] ?? 5)
            );
        }

        if (! empty($filters['risk_level'])) {
            $query->byRiskLevel((string) $filters['risk_level']);
        }

        if (empty($filters['include_archived'])) {
            $query->where('status', '!=', 'archived');
        }

        return $query
            ->orderByDesc('updated_at')
            ->paginate(
                min((int) ($filters['per_page'] ?? 50), 100),
                ['*'],
                'page',
                (int) ($filters['page'] ?? 1)
            );
    }

    /**
     * @param  array<string, mixed>  $validated
     */
    public function store(array $validated, ?int $userId, ?string $fallbackUsername): HazardReport
    {
        $payload = $this->normalizeStorePayload($validated, $userId, $fallbackUsername);
        $comments = (array) ($validated['comments'] ?? []);
        unset($payload['comments']);

        $hazard = HazardReport::create($payload);

        if ($comments !== []) {
            $this->commentSyncService->syncComments($hazard, $comments);
        }

        return $hazard->load(['comments', 'comments.user', 'riskLevel', 'category', 'estimatedDuration']);
    }

    public function canMutate(?int $userId, HazardReport $hazardReport): bool
    {
        return $userId !== null && (int) $hazardReport->user_id === (int) $userId;
    }

    /**
     * @param  array<string, mixed>  $validated
     * @return array{conflict: bool, hazard: HazardReport}
     */
    public function update(HazardReport $hazardReport, array $validated): array
    {
        $comments = (array) ($validated['comments'] ?? []);
        $payload = $this->normalizeUpdatePayload($validated);
        unset($payload['comments']);

        $hazardReport->update($payload);

        if ($comments !== []) {
            $this->commentSyncService->syncComments($hazardReport, $comments);
        }

        return [
            'conflict' => false,
            'hazard' => $hazardReport->load(['comments', 'comments.user', 'riskLevel', 'category', 'estimatedDuration']),
        ];
    }

    public function delete(HazardReport $hazardReport): void
    {
        $hazardReport->comments()->delete();
        $hazardReport->delete();
    }

    public function unsynced()
    {
        return HazardReport::query()->unsynced()->get();
    }

    /**
     * @param  array<int, array<string, mixed>>  $hazards
     * @return array<string, mixed>
     */
    public function sync(array $hazards, ?int $userId): array
    {
        $syncResults = [
            'synced' => 0,
            'conflicts' => 0,
            'errors' => 0,
            'details' => [],
        ];

        foreach ($hazards as $hazardData) {
            try {
                $commentsData = (array) ($hazardData['comments'] ?? []);
                unset($hazardData['comments']);

                $hazardData['risk_level_code'] = $this->normalizer->normalizeRiskCode($hazardData['risk_level_code'] ?? null);
                $hazardData['category_code'] = $this->normalizer->normalizeCategoryCode($hazardData['category_code'] ?? null);
                $hazardData['estimated_duration_code'] = $this->normalizer->normalizeDurationCode($hazardData['estimated_duration_code'] ?? null);
                $hazardData['narrative_description'] = $hazardData['narrative_description'] ?? ($hazardData['description'] ?? null);
                $hazardData['description'] = $hazardData['description'] ?? $hazardData['narrative_description'];

                $existing = HazardReport::query()
                    ->where(function ($query) use ($hazardData): void {
                        if (! empty($hazardData['remote_id'])) {
                            $query->where('remote_id', $hazardData['remote_id'])
                                ->orWhere('id', $hazardData['remote_id']);
                        }

                        $query->orWhere('local_id', $hazardData['local_id']);
                    })
                    ->first();

                $remoteTimestamp = Carbon::parse($hazardData['last_modified_at']);

                if ($existing) {
                    if ($remoteTimestamp->greaterThan($existing->last_modified_at)) {
                        $existing->update(array_merge(
                            $hazardData,
                            [
                                'status' => 'synced',
                                'remote_id' => $hazardData['remote_id'] ?? $existing->remote_id,
                                'synced_at' => now(),
                                'user_id' => $existing->user_id ?? $userId,
                            ]
                        ));

                        if ($commentsData !== []) {
                            $this->commentSyncService->syncComments($existing, $commentsData);
                        }

                        $syncResults['synced']++;
                    } else {
                        $syncResults['conflicts']++;
                        $syncResults['details'][] = [
                            'local_id' => $hazardData['local_id'],
                            'status' => 'conflict',
                            'reason' => 'Local version is newer or equal',
                        ];
                    }

                    continue;
                }

                $created = HazardReport::create(array_merge(
                    $hazardData,
                    [
                        'status' => 'synced',
                        'remote_id' => $hazardData['remote_id'] ?? null,
                        'synced_at' => now(),
                        'user_id' => $userId,
                    ]
                ));
                $this->ensureRemoteId($created);

                if ($commentsData !== []) {
                    $this->commentSyncService->syncComments($created, $commentsData);
                }

                $syncResults['synced']++;
            } catch (Throwable $error) {
                $syncResults['errors']++;
                $syncResults['details'][] = [
                    'local_id' => $hazardData['local_id'] ?? 'unknown',
                    'status' => 'error',
                    'error' => $error->getMessage(),
                ];

                Log::error('Hazard sync item error', [
                    'local_id' => $hazardData['local_id'] ?? 'unknown',
                    'error' => $error->getMessage(),
                ]);
            }
        }

        return $syncResults;
    }

    /**
     * @param  array<string, mixed>  $validated
     * @return array<string, mixed>
     */
    private function normalizeStorePayload(array $validated, ?int $userId, ?string $fallbackUsername): array
    {
        $validated['risk_level_code'] = $this->normalizer->normalizeRiskCode($validated['risk_level_code'] ?? null);
        $validated['category_code'] = $this->normalizer->normalizeCategoryCode($validated['category_code'] ?? null);
        $validated['estimated_duration_code'] = $this->normalizer->normalizeDurationCode($validated['estimated_duration_code'] ?? null);
        $validated['narrative_description'] = $validated['narrative_description'] ?? ($validated['description'] ?? null);
        $validated['description'] = $validated['description'] ?? $validated['narrative_description'];
        $validated['reported_by_username'] = $validated['reported_by_username'] ?? $fallbackUsername ?? 'Anonimo';
        $validated['status'] = 'created';
        $validated['user_id'] = $userId;

        return $validated;
    }

    /**
     * @param  array<string, mixed>  $validated
     * @return array<string, mixed>
     */
    private function normalizeUpdatePayload(array $validated): array
    {
        if (array_key_exists('risk_level_code', $validated)) {
            $validated['risk_level_code'] = $this->normalizer->normalizeRiskCode($validated['risk_level_code']);
        }

        if (array_key_exists('category_code', $validated)) {
            $validated['category_code'] = $this->normalizer->normalizeCategoryCode($validated['category_code']);
        }

        if (array_key_exists('estimated_duration_code', $validated)) {
            $validated['estimated_duration_code'] = $this->normalizer->normalizeDurationCode($validated['estimated_duration_code']);
        }

        if (array_key_exists('narrative_description', $validated) && ! array_key_exists('description', $validated)) {
            $validated['description'] = $validated['narrative_description'];
        }

        if (array_key_exists('description', $validated) && ! array_key_exists('narrative_description', $validated)) {
            $validated['narrative_description'] = $validated['description'];
        }

        return $validated;
    }

    private function ensureRemoteId(HazardReport $hazardReport): void
    {
        $hazardReport->update([
            'remote_id' => $hazardReport->remote_id ?? (string) $hazardReport->id,
        ]);
    }
}
