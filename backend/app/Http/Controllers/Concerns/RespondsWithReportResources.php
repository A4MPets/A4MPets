<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\JsonResponse;

trait RespondsWithReportResources
{
    protected function paginated(LengthAwarePaginator $reports): JsonResponse
    {
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

    protected function data(mixed $data, int $status = 200): JsonResponse
    {
        return response()->json(['success' => true, 'data' => $data], $status);
    }

    protected function unauthorized(): JsonResponse
    {
        return response()->json(['success' => false, 'message' => 'No autorizado'], 403);
    }

    protected function deleted(): JsonResponse
    {
        return response()->json(['success' => true, 'message' => 'Reporte eliminado']);
    }

    protected function commentsFor(Model $report, array $relations): JsonResponse
    {
        $report->load($relations);

        return $this->data($report->comments->map(fn ($comment) => $this->reportCommentFormatter->formatComment($comment))->values());
    }

    protected function createdComment(mixed $comment): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => 'Comentario agregado exitosamente',
            'data' => $this->reportCommentFormatter->formatComment($comment),
        ], 201);
    }
}
