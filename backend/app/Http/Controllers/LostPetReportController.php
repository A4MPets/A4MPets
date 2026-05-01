<?php

namespace App\Http\Controllers;

use App\Http\Requests\Reports\StoreLostPetReportRequest;
use App\Http\Requests\Reports\StoreReportCommentRequest;
use App\Http\Requests\Reports\SyncLostPetReportsRequest;
use App\Http\Requests\Reports\UpdateLostPetReportRequest;
use App\Models\LostPetReport;
use App\Services\Comments\ReportCommentFormatter;
use App\Services\Comments\ReportCommentService;
use App\Services\Reports\LostPetReportService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LostPetReportController extends Controller
{
    public function __construct(
        private readonly LostPetReportService $lostPetReportService,
        private readonly ReportCommentService $reportCommentService,
        private readonly ReportCommentFormatter $reportCommentFormatter
    ) {}

    public function index(Request $request): JsonResponse
    {
        $reports = $this->lostPetReportService->paginate(
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

    public function show(LostPetReport $lostPetReport): JsonResponse
    {
        $lostPetReport->load(['comments', 'comments.user']);

        return response()->json([
            'success' => true,
            'data' => $lostPetReport,
        ]);
    }

    public function store(StoreLostPetReportRequest $request): JsonResponse
    {
        $report = $this->lostPetReportService->store(
            $request->user()?->id,
            $request->validated()
        );

        return response()->json([
            'success' => true,
            'data' => $report,
        ], 201);
    }

    public function update(UpdateLostPetReportRequest $request, LostPetReport $lostPetReport): JsonResponse
    {
        $report = $this->lostPetReportService->update($lostPetReport, $request->validated());

        return response()->json([
            'success' => true,
            'data' => $report,
        ]);
    }

    public function destroy(LostPetReport $lostPetReport): JsonResponse
    {
        $this->lostPetReportService->delete($lostPetReport);

        return response()->json([
            'success' => true,
            'message' => 'Reporte marcado para eliminacion',
        ]);
    }

    public function sync(SyncLostPetReportsRequest $request): JsonResponse
    {
        $results = $this->lostPetReportService->sync(
            $request->user()?->id,
            $request->validated('lost_pet_reports')
        );

        return response()->json([
            'success' => true,
            'sync_results' => $results,
        ]);
    }

    public function comments(LostPetReport $lostPetReport): JsonResponse
    {
        $lostPetReport->load(['comments', 'comments.user']);

        return response()->json([
            'success' => true,
            'data' => $lostPetReport->comments
                ->map(fn ($comment) => $this->reportCommentFormatter->formatComment($comment))
                ->values(),
        ]);
    }

    public function storeComment(StoreReportCommentRequest $request, LostPetReport $lostPetReport): JsonResponse
    {
        $comment = $this->reportCommentService->storeComment(
            $lostPetReport,
            $request->user(),
            $request->validated()
        );

        return response()->json([
            'success' => true,
            'message' => 'Comentario agregado exitosamente',
            'data' => $this->reportCommentFormatter->formatComment($comment),
        ], 201);
    }
}
