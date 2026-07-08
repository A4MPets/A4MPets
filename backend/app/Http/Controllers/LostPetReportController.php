<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\RespondsWithReportResources;
use App\Http\Requests\Reports\StoreLostPetReportRequest;
use App\Http\Requests\Reports\StoreReportCommentRequest;
use App\Http\Requests\Reports\UpdateLostPetReportRequest;
use App\Models\LostPetReport;
use App\Services\Comments\ReportCommentFormatter;
use App\Services\Comments\ReportCommentService;
use App\Services\Reports\LostPetReportService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LostPetReportController extends Controller
{
    use RespondsWithReportResources;

    private const RELATIONS = ['comments', 'comments.user'];

    public function __construct(
        private readonly LostPetReportService $lostPetReportService,
        private readonly ReportCommentService $reportCommentService,
        private readonly ReportCommentFormatter $reportCommentFormatter
    ) {}

    public function index(Request $request): JsonResponse
    {
        return $this->paginated($this->lostPetReportService->paginate(
            $request->boolean('include_archived'),
            min((int) $request->query('per_page', 50), 100),
            (int) $request->query('page', 1)
        ));
    }

    public function show(LostPetReport $lostPetReport): JsonResponse
    {
        return $this->data($lostPetReport->load(self::RELATIONS));
    }

    public function store(StoreLostPetReportRequest $request): JsonResponse
    {
        if (! $request->user()) {
            return response()->json(['success' => false, 'message' => 'Debes iniciar sesion para reportar mascotas perdidas.'], 401);
        }

        return $this->data($this->lostPetReportService->store($request->user()?->id, $request->validated()), 201);
    }

    public function update(UpdateLostPetReportRequest $request, LostPetReport $lostPetReport): JsonResponse
    {
        if (! $this->lostPetReportService->canMutate($request->user()?->id, $lostPetReport)) {
            return $this->unauthorized();
        }

        return $this->data($this->lostPetReportService->update($lostPetReport, $request->validated()));
    }

    public function destroy(LostPetReport $lostPetReport): JsonResponse
    {
        if (! $this->lostPetReportService->canMutate(request()->user()?->id, $lostPetReport)) {
            return $this->unauthorized();
        }

        $this->lostPetReportService->delete($lostPetReport);

        return $this->deleted();
    }

    public function comments(LostPetReport $lostPetReport): JsonResponse
    {
        return $this->commentsFor($lostPetReport, self::RELATIONS);
    }

    public function storeComment(StoreReportCommentRequest $request, LostPetReport $lostPetReport): JsonResponse
    {
        return $this->createdComment($this->reportCommentService->storeComment($lostPetReport, $request->user(), $request->validated()));
    }
}
