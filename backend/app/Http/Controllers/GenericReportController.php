<?php

namespace App\Http\Controllers;

use App\Http\Requests\Reports\StoreGenericReportRequest;
use App\Http\Requests\Reports\StoreReportCommentRequest;
use App\Http\Requests\Reports\SyncGenericReportsRequest;
use App\Http\Requests\Reports\UpdateGenericReportRequest;
use App\Models\GenericReport;
use App\Services\Comments\ReportCommentFormatter;
use App\Services\Comments\ReportCommentService;
use App\Services\Reports\GenericReportService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class GenericReportController extends Controller
{
    public function __construct(
        private readonly GenericReportService $genericReportService,
        private readonly ReportCommentService $reportCommentService,
        private readonly ReportCommentFormatter $reportCommentFormatter
    ) {}

    public function index(Request $request): JsonResponse
    {
        $reports = $this->genericReportService->paginate(
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

    public function show(GenericReport $genericReport): JsonResponse
    {
        $genericReport->load(['comments', 'comments.user']);

        return response()->json([
            'success' => true,
            'data' => $genericReport,
        ]);
    }

    public function store(StoreGenericReportRequest $request): JsonResponse
    {
        $report = $this->genericReportService->store(
            $request->user()?->id,
            $request->validated()
        );

        return response()->json([
            'success' => true,
            'data' => $report,
        ], 201);
    }

    public function update(UpdateGenericReportRequest $request, GenericReport $genericReport): JsonResponse
    {
        $report = $this->genericReportService->update($genericReport, $request->validated());

        return response()->json([
            'success' => true,
            'data' => $report,
        ]);
    }

    public function destroy(GenericReport $genericReport): JsonResponse
    {
        $this->genericReportService->delete($genericReport);

        return response()->json([
            'success' => true,
            'message' => 'Reporte marcado para eliminacion',
        ]);
    }

    public function sync(SyncGenericReportsRequest $request): JsonResponse
    {
        $results = $this->genericReportService->sync(
            $request->user()?->id,
            $request->validated('generic_reports')
        );

        return response()->json([
            'success' => true,
            'sync_results' => $results,
        ]);
    }

    public function comments(GenericReport $genericReport): JsonResponse
    {
        $genericReport->load(['comments', 'comments.user']);

        return response()->json([
            'success' => true,
            'data' => $genericReport->comments
                ->map(fn ($comment) => $this->reportCommentFormatter->formatComment($comment))
                ->values(),
        ]);
    }

    public function storeComment(StoreReportCommentRequest $request, GenericReport $genericReport): JsonResponse
    {
        $comment = $this->reportCommentService->storeComment(
            $genericReport,
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
