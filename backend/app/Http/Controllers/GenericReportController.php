<?php

namespace App\Http\Controllers;

use App\Models\GenericReport;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class GenericReportController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = GenericReport::query();

        if (!$request->boolean('include_archived')) {
            $query->where('sync_status', '!=', 'deleted');
        }

        $perPage = min((int) $request->query('per_page', 50), 100);
        $page = (int) $request->query('page', 1);

        $reports = $query->orderByDesc('last_modified_at')
            ->paginate($perPage, ['*'], 'page', $page);

        return response()->json([
            'success' => true,
            'data' => $reports->items(),
            'pagination' => [
                'total' => $reports->total(),
                'per_page' => $reports->perPage(),
                'current_page' => $reports->currentPage(),
                'last_page' => $reports->lastPage(),
            ],
        ]);
    }

    public function show(GenericReport $genericReport): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data' => $genericReport,
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'local_id' => ['required', 'string'],
            'latitude' => ['required', 'numeric'],
            'longitude' => ['required', 'numeric'],
            'description' => ['required', 'string'],
            'reported_date' => ['required', 'date'],
            'risk_level_code' => ['required', 'string'],
            'photo_url' => ['nullable', 'string', 'max:500'],
        ]);

        $report = GenericReport::updateOrCreate(
            ['local_id' => $validated['local_id']],
            [
                'user_id' => $request->user()?->id,
                'latitude' => $validated['latitude'],
                'longitude' => $validated['longitude'],
                'description' => $validated['description'],
                'reported_date' => $validated['reported_date'],
                'risk_level_code' => $this->normalizeRiskCode($validated['risk_level_code']),
                'photo_url' => $validated['photo_url'] ?? null,
                'sync_status' => 'synced',
                'last_modified_at' => now(),
                'synced_at' => now(),
            ]
        );

        $report->update([
            'remote_id' => $report->remote_id ?? (string) $report->id,
        ]);

        return response()->json([
            'success' => true,
            'data' => $report->refresh(),
        ], 201);
    }

    public function update(Request $request, GenericReport $genericReport): JsonResponse
    {
        $validated = $request->validate([
            'latitude' => ['required', 'numeric'],
            'longitude' => ['required', 'numeric'],
            'description' => ['required', 'string'],
            'reported_date' => ['required', 'date'],
            'risk_level_code' => ['required', 'string'],
            'photo_url' => ['nullable', 'string', 'max:500'],
        ]);

        $genericReport->update([
            'latitude' => $validated['latitude'],
            'longitude' => $validated['longitude'],
            'description' => $validated['description'],
            'reported_date' => $validated['reported_date'],
            'risk_level_code' => $this->normalizeRiskCode($validated['risk_level_code']),
            'photo_url' => $validated['photo_url'] ?? null,
            'sync_status' => 'synced',
            'last_modified_at' => now(),
            'synced_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'data' => $genericReport->refresh(),
        ]);
    }

    public function destroy(GenericReport $genericReport): JsonResponse
    {
        $genericReport->update([
            'sync_status' => 'deleted',
            'last_modified_at' => now(),
            'synced_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Reporte marcado para eliminacion',
        ]);
    }

    public function sync(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'generic_reports' => ['required', 'array'],
            'generic_reports.*.local_id' => ['required', 'string'],
            'generic_reports.*.remote_id' => ['nullable', 'string'],
            'generic_reports.*.latitude' => ['required', 'numeric'],
            'generic_reports.*.longitude' => ['required', 'numeric'],
            'generic_reports.*.description' => ['required', 'string'],
            'generic_reports.*.reported_date' => ['required', 'date_format:Y-m-d H:i:s'],
            'generic_reports.*.risk_level_code' => ['required', 'string'],
            'generic_reports.*.photo_url' => ['nullable', 'string', 'max:500'],
            'generic_reports.*.sync_status' => ['nullable', 'string', 'max:32'],
            'generic_reports.*.last_modified_at' => ['required', 'date_format:Y-m-d H:i:s'],
        ]);

        $results = [
            'synced' => 0,
            'deleted' => 0,
            'errors' => 0,
            'details' => [],
        ];

        foreach ($validated['generic_reports'] as $reportData) {
            try {
                $report = GenericReport::query()
                    ->where(function ($query) use ($reportData): void {
                        if (!empty($reportData['remote_id'])) {
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
                    'user_id' => $request->user()?->id,
                    'latitude' => $reportData['latitude'],
                    'longitude' => $reportData['longitude'],
                    'description' => $reportData['description'],
                    'reported_date' => $reportData['reported_date'],
                    'risk_level_code' => $this->normalizeRiskCode($reportData['risk_level_code'] ?? null),
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

                $report->update([
                    'remote_id' => $report->remote_id ?? (string) $report->id,
                ]);

                $results['synced']++;
            } catch (\Throwable $error) {
                $results['errors']++;
                $results['details'][] = [
                    'local_id' => $reportData['local_id'] ?? 'unknown',
                    'status' => 'error',
                    'error' => $error->getMessage(),
                ];
            }
        }

        return response()->json([
            'success' => true,
            'sync_results' => $results,
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
}
