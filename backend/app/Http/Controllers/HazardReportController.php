<?php

namespace App\Http\Controllers;

use App\Http\Requests\Hazards\StoreHazardRequest;
use App\Http\Requests\Hazards\UpdateHazardRequest;
use App\Http\Requests\Reports\StoreReportCommentRequest;
use App\Models\HazardReport;
use App\Services\Comments\ReportCommentFormatter;
use App\Services\Comments\ReportCommentService;
use App\Services\Hazards\HazardReportService;
use App\Services\Hazards\HazardResponseFormatter;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class HazardReportController extends Controller
{
    public function __construct(
        private readonly HazardReportService $hazardReportService,
        private readonly ReportCommentService $reportCommentService,
        private readonly HazardResponseFormatter $hazardResponseFormatter,
        private readonly ReportCommentFormatter $reportCommentFormatter
    ) {}

    public function index(Request $request): JsonResponse
    {
        $hazards = $this->hazardReportService->paginate($request->query());

        return response()->json([
            'success' => true,
            'data' => array_map(
                fn (HazardReport $hazard) => $this->hazardResponseFormatter->formatHazard($hazard, includeComments: false),
                $hazards->items()
            ),
            'pagination' => [
                'total' => $hazards->total(),
                'per_page' => $hazards->perPage(),
                'current_page' => $hazards->currentPage(),
                'last_page' => $hazards->lastPage(),
            ],
        ]);
    }

    public function store(StoreHazardRequest $request): JsonResponse
    {
        $hazard = $this->hazardReportService->store(
            $request->validated(),
            $request->user()?->id,
            $request->user()?->name
        );

        return response()->json([
            'success' => true,
            'message' => 'Peligro creado exitosamente',
            'data' => $this->hazardResponseFormatter->formatHazard($hazard),
        ], 201);
    }

    public function show(HazardReport $hazardReport): JsonResponse
    {
        $hazardReport->load(['comments', 'comments.user', 'riskLevel', 'category', 'estimatedDuration']);

        return response()->json([
            'success' => true,
            'data' => $this->hazardResponseFormatter->formatHazard($hazardReport),
        ]);
    }

    public function update(UpdateHazardRequest $request, HazardReport $hazardReport): JsonResponse
    {
        if (! $this->hazardReportService->canMutate($request->user()?->id, $hazardReport)) {
            return response()->json([
                'success' => false,
                'message' => 'No autorizado',
            ], 403);
        }

        $result = $this->hazardReportService->update($hazardReport, $request->validated());

        if ($result['conflict']) {
            return response()->json([
                'success' => false,
                'message' => 'Conflicto: version local es mas nueva (last_write_wins)',
                'data' => $result['hazard'],
            ], 409);
        }

        return response()->json([
            'success' => true,
            'message' => 'Peligro actualizado exitosamente',
            'data' => $this->hazardResponseFormatter->formatHazard($result['hazard']),
        ]);
    }

    public function destroy(HazardReport $hazardReport): JsonResponse
    {
        if (! $this->hazardReportService->canDelete(request()->user()?->id)) {
            return response()->json([
                'success' => false,
                'message' => 'No autorizado',
            ], 403);
        }

        $this->hazardReportService->delete($hazardReport);

        return response()->json([
            'success' => true,
            'message' => 'Peligro eliminado exitosamente',
        ]);
    }

    public function comments(HazardReport $hazardReport): JsonResponse
    {
        $hazardReport->load(['comments', 'comments.user', 'riskLevel', 'category', 'estimatedDuration']);

        return response()->json([
            'success' => true,
            'data' => $hazardReport->comments
                ->map(fn ($comment) => $this->reportCommentFormatter->formatComment($comment))
                ->values(),
        ]);
    }

    public function storeComment(StoreReportCommentRequest $request, HazardReport $hazardReport): JsonResponse
    {
        $comment = $this->reportCommentService->storeComment(
            $hazardReport,
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
