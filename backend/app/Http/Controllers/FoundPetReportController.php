<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\RespondsWithReportResources;
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
    use RespondsWithReportResources;

    private const RELATIONS = ['comments', 'comments.user'];

    public function __construct(
        private readonly FoundPetReportService $foundPetReportService,
        private readonly ReportCommentService $reportCommentService,
        private readonly ReportCommentFormatter $reportCommentFormatter
    ) {}

    public function index(Request $request): JsonResponse
    {
        return $this->paginated($this->foundPetReportService->paginate(
            $request->boolean('include_archived'),
            min((int) $request->query('per_page', 50), 100),
            (int) $request->query('page', 1)
        ));
    }

    public function show(FoundPetReport $foundPetReport): JsonResponse
    {
        return $this->data($foundPetReport->load(self::RELATIONS));
    }

    public function store(StoreFoundPetReportRequest $request): JsonResponse
    {
        if (! $request->user()) {
            return response()->json(['success' => false, 'message' => 'Debes iniciar sesion para reportar mascotas encontradas.'], 401);
        }

        return $this->data($this->foundPetReportService->store($request->user()?->id, $request->validated()), 201);
    }

    public function update(UpdateFoundPetReportRequest $request, FoundPetReport $foundPetReport): JsonResponse
    {
        if (! $this->foundPetReportService->canMutate($request->user()?->id, $foundPetReport)) {
            return $this->unauthorized();
        }

        return $this->data($this->foundPetReportService->update($foundPetReport, $request->validated()));
    }

    public function destroy(FoundPetReport $foundPetReport): JsonResponse
    {
        if (! $this->foundPetReportService->canMutate(request()->user()?->id, $foundPetReport)) {
            return $this->unauthorized();
        }

        $this->foundPetReportService->delete($foundPetReport);

        return $this->deleted();
    }

    public function comments(FoundPetReport $foundPetReport): JsonResponse
    {
        return $this->commentsFor($foundPetReport, self::RELATIONS);
    }

    public function storeComment(StoreReportCommentRequest $request, FoundPetReport $foundPetReport): JsonResponse
    {
        return $this->createdComment($this->reportCommentService->storeComment($foundPetReport, $request->user(), $request->validated()));
    }
}
