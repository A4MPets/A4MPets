<?php

namespace App\Http\Controllers;

use App\Models\LostPetReport;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LostPetReportController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = LostPetReport::query();

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

    public function show(LostPetReport $lostPetReport): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data' => $lostPetReport,
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'local_id' => ['required', 'string'],
            'last_seen_latitude' => ['required', 'numeric'],
            'last_seen_longitude' => ['required', 'numeric'],
            'name' => ['required', 'string', 'max:255'],
            'details' => ['required', 'string'],
            'disappearance_date' => ['required', 'date'],
            'photo_url' => ['nullable', 'string', 'max:500'],
            'phone' => ['nullable', 'string', 'max:64'],
        ]);

        $report = LostPetReport::updateOrCreate(
            ['local_id' => $validated['local_id']],
            [
                'user_id' => $request->user()?->id,
                'last_seen_latitude' => $validated['last_seen_latitude'],
                'last_seen_longitude' => $validated['last_seen_longitude'],
                'name' => $validated['name'],
                'details' => $validated['details'],
                'disappearance_date' => $validated['disappearance_date'],
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

    public function update(Request $request, LostPetReport $lostPetReport): JsonResponse
    {
        $validated = $request->validate([
            'last_seen_latitude' => ['required', 'numeric'],
            'last_seen_longitude' => ['required', 'numeric'],
            'name' => ['required', 'string', 'max:255'],
            'details' => ['required', 'string'],
            'disappearance_date' => ['required', 'date'],
            'photo_url' => ['nullable', 'string', 'max:500'],
            'phone' => ['nullable', 'string', 'max:64'],
        ]);

        $lostPetReport->update([
            'last_seen_latitude' => $validated['last_seen_latitude'],
            'last_seen_longitude' => $validated['last_seen_longitude'],
            'name' => $validated['name'],
            'details' => $validated['details'],
            'disappearance_date' => $validated['disappearance_date'],
            'photo_url' => $validated['photo_url'] ?? null,
            'phone' => $validated['phone'] ?? null,
            'sync_status' => 'synced',
            'last_modified_at' => now(),
            'synced_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'data' => $lostPetReport->refresh(),
        ]);
    }

    public function destroy(LostPetReport $lostPetReport): JsonResponse
    {
        $lostPetReport->update([
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
            'lost_pet_reports' => ['required', 'array'],
            'lost_pet_reports.*.local_id' => ['required', 'string'],
            'lost_pet_reports.*.remote_id' => ['nullable', 'string'],
            'lost_pet_reports.*.last_seen_latitude' => ['required', 'numeric'],
            'lost_pet_reports.*.last_seen_longitude' => ['required', 'numeric'],
            'lost_pet_reports.*.name' => ['required', 'string', 'max:255'],
            'lost_pet_reports.*.details' => ['required', 'string'],
            'lost_pet_reports.*.disappearance_date' => ['required', 'date_format:Y-m-d H:i:s'],
            'lost_pet_reports.*.photo_url' => ['nullable', 'string', 'max:500'],
            'lost_pet_reports.*.phone' => ['nullable', 'string', 'max:64'],
            'lost_pet_reports.*.sync_status' => ['nullable', 'string', 'max:32'],
            'lost_pet_reports.*.last_modified_at' => ['required', 'date_format:Y-m-d H:i:s'],
        ]);

        $results = [
            'synced' => 0,
            'deleted' => 0,
            'errors' => 0,
            'details' => [],
        ];

        foreach ($validated['lost_pet_reports'] as $reportData) {
            try {
                $report = LostPetReport::query()
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
                    'last_seen_latitude' => $reportData['last_seen_latitude'],
                    'last_seen_longitude' => $reportData['last_seen_longitude'],
                    'name' => $reportData['name'],
                    'details' => $reportData['details'],
                    'disappearance_date' => $reportData['disappearance_date'],
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
                    $report = LostPetReport::create($payload);
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
