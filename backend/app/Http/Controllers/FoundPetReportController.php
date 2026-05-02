<?php

namespace App\Http\Controllers;

use App\Http\Requests\Reports\StoreFoundPetReportRequest;
use App\Http\Requests\Reports\StoreReportCommentRequest;
use App\Http\Requests\Reports\UpdateFoundPetReportRequest;
use App\Models\FoundPetReport;
use App\Services\Comments\ReportCommentFormatter;
use App\Services\Comments\ReportCommentService;
use App\Services\Reports\FoundPetReportService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class FoundPetReportController extends Controller
{
    public function __construct(
        private readonly FoundPetReportService $foundPetReportService,
        private readonly ReportCommentService $reportCommentService,
        private readonly ReportCommentFormatter $reportCommentFormatter
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
        $foundPetReport->load(['comments', 'comments.user']);

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
        if (! $this->foundPetReportService->canMutate($request->user()?->id, $foundPetReport)) {
            return response()->json([
                'success' => false,
                'message' => 'No autorizado',
            ], 403);
        }

        $report = $this->foundPetReportService->update($foundPetReport, $request->validated());

        return response()->json([
            'success' => true,
            'data' => $report,
        ]);
    }

    public function destroy(FoundPetReport $foundPetReport): JsonResponse
    {
        if (! $this->foundPetReportService->canMutate(request()->user()?->id, $foundPetReport)) {
            return response()->json([
                'success' => false,
                'message' => 'No autorizado',
            ], 403);
        }

        $this->foundPetReportService->delete($foundPetReport);

        return response()->json([
            'success' => true,
            'message' => 'Reporte eliminado',
        ]);
    }

    public function comments(FoundPetReport $foundPetReport): JsonResponse
    {
        $foundPetReport->load(['comments', 'comments.user']);

        return response()->json([
            'success' => true,
            'data' => $foundPetReport->comments
                ->map(fn ($comment) => $this->reportCommentFormatter->formatComment($comment))
                ->values(),
        ]);
    }

    public function storeComment(StoreReportCommentRequest $request, FoundPetReport $foundPetReport): JsonResponse
    {
        $comment = $this->reportCommentService->storeComment(
            $foundPetReport,
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
