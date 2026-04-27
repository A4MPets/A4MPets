<?php

namespace App\Http\Controllers;

use App\Http\Requests\Reports\StoreFoundPetReportRequest;
use App\Http\Requests\Reports\SyncFoundPetReportsRequest;
use App\Http\Requests\Reports\UpdateFoundPetReportRequest;
use App\Models\FoundPetReport;
use App\Services\Reports\FoundPetReportService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FoundPetReportController extends Controller
{
    public function __construct(
        private readonly FoundPetReportService $foundPetReportService
    ) {}

    public function index(Request $request): JsonResponse
    {
        $reports = $this->foundPetReportService->paginate(
            $request->boolean('include_archived'),
            min((int) $request->query('per_page', 50), 100),
            (int) $request->query('page', 1)
        );

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

    public function store(StoreFoundPetReportRequest $request): JsonResponse
    {
        $report = $this->foundPetReportService->store(
            $request->user()?->id,
            $request->validated()
        );

        return response()->json([
            'success' => true,
            'data' => $report,
        ], 201);
    }

    public function update(UpdateFoundPetReportRequest $request, FoundPetReport $foundPetReport): JsonResponse
    {
        $report = $this->foundPetReportService->update($foundPetReport, $request->validated());

        return response()->json([
            'success' => true,
            'data' => $report,
        ]);
    }

    public function destroy(FoundPetReport $foundPetReport): JsonResponse
    {
        $this->foundPetReportService->delete($foundPetReport);

        return response()->json([
            'success' => true,
            'message' => 'Reporte marcado para eliminacion',
        ]);
    }

    public function sync(SyncFoundPetReportsRequest $request): JsonResponse
    {
        $results = $this->foundPetReportService->sync(
            $request->user()?->id,
            $request->validated('found_pet_reports')
        );

        return response()->json([
            'success' => true,
            'sync_results' => $results,
        ]);
    }
}
