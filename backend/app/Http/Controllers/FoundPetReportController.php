<?php

namespace App\Http\Controllers;

use App\Models\FoundPetReport;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FoundPetReportController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = FoundPetReport::query();

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

    public function show(FoundPetReport $foundPetReport): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data' => $foundPetReport,
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'local_id' => ['required', 'string'],
            'latitude' => ['required', 'numeric'],
            'longitude' => ['required', 'numeric'],
            'details' => ['required', 'string'],
            'found_date' => ['required', 'date'],
            'photo_url' => ['nullable', 'string', 'max:500'],
            'phone' => ['nullable', 'string', 'max:64'],
        ]);

        $report = FoundPetReport::updateOrCreate(
            ['local_id' => $validated['local_id']],
            [
                'user_id' => $request->user()?->id,
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

        $report->update([
            'remote_id' => $report->remote_id ?? (string) $report->id,
        ]);

        return response()->json([
            'success' => true,
            'data' => $report->refresh(),
        ], 201);
    }

    public function update(Request $request, FoundPetReport $foundPetReport): JsonResponse
    {
        $validated = $request->validate([
            'latitude' => ['required', 'numeric'],
            'longitude' => ['required', 'numeric'],
            'details' => ['required', 'string'],
            'found_date' => ['required', 'date'],
            'photo_url' => ['nullable', 'string', 'max:500'],
            'phone' => ['nullable', 'string', 'max:64'],
        ]);

        $foundPetReport->update([
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

        return response()->json([
            'success' => true,
            'data' => $foundPetReport->refresh(),
        ]);
    }

    public function destroy(FoundPetReport $foundPetReport): JsonResponse
    {
        $foundPetReport->update([
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
            'found_pet_reports' => ['required', 'array'],
            'found_pet_reports.*.local_id' => ['required', 'string'],
            'found_pet_reports.*.remote_id' => ['nullable', 'string'],
            'found_pet_reports.*.latitude' => ['required', 'numeric'],
            'found_pet_reports.*.longitude' => ['required', 'numeric'],
            'found_pet_reports.*.details' => ['required', 'string'],
            'found_pet_reports.*.found_date' => ['required', 'date_format:Y-m-d H:i:s'],
            'found_pet_reports.*.photo_url' => ['nullable', 'string', 'max:500'],
            'found_pet_reports.*.phone' => ['nullable', 'string', 'max:64'],
            'found_pet_reports.*.sync_status' => ['nullable', 'string', 'max:32'],
            'found_pet_reports.*.last_modified_at' => ['required', 'date_format:Y-m-d H:i:s'],
        ]);

        $results = [
            'synced' => 0,
            'deleted' => 0,
            'errors' => 0,
            'details' => [],
        ];

        foreach ($validated['found_pet_reports'] as $reportData) {
            try {
                $report = FoundPetReport::query()
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
}
