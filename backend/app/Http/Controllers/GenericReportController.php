<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Concerns\RespondsWithReportResources;
use App\Http\Requests\Reports\StoreGenericReportRequest;
use App\Http\Requests\Reports\StoreReportCommentRequest;
use App\Http\Requests\Reports\UpdateGenericReportRequest;
use App\Models\GenericReport;
use App\Services\Comments\ReportCommentFormatter;
use App\Services\Comments\ReportCommentService;
use App\Services\Reports\GenericReportService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class GenericReportController extends Controller
{
    use RespondsWithReportResources;

    private const RELATIONS = ['user', 'comments', 'comments.user'];

    public function __construct(
        private readonly GenericReportService $genericReportService,
        private readonly ReportCommentService $reportCommentService,
        private readonly ReportCommentFormatter $reportCommentFormatter
    ) {}

    public function index(Request $request): JsonResponse
    {
        return $this->paginated($this->genericReportService->paginate(
            $request->boolean('include_archived'),
            min((int) $request->query('per_page', 50), 100),
            (int) $request->query('page', 1)
        ));
    }

    public function show(GenericReport $genericReport): JsonResponse
    {
        return $this->data($genericReport->load(self::RELATIONS));
    }

    public function store(StoreGenericReportRequest $request): JsonResponse
    {
        return $this->data($this->genericReportService->store($request->user()?->id, $request->validated()), 201);
    }

    public function update(UpdateGenericReportRequest $request, GenericReport $genericReport): JsonResponse
    {
        if (! $this->genericReportService->canMutate($request->user()?->id, $genericReport)) {
            return $this->unauthorized();
        }

        return $this->data($this->genericReportService->update($genericReport, $request->validated()));
    }

    public function destroy(GenericReport $genericReport): JsonResponse
    {
        if (! $this->genericReportService->canMutate(request()->user()?->id, $genericReport)) {
            return $this->unauthorized();
        }

        $this->genericReportService->delete($genericReport);

        return $this->deleted();
    }

    public function comments(GenericReport $genericReport): JsonResponse
    {
        return $this->commentsFor($genericReport, self::RELATIONS);
    }

    public function storeComment(StoreReportCommentRequest $request, GenericReport $genericReport): JsonResponse
    {
        return $this->createdComment($this->reportCommentService->storeComment($genericReport, $request->user(), $request->validated()));
    }
}
