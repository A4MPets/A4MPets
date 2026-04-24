<?php

namespace App\Http\Controllers;

use App\Models\HazardComment;
use App\Models\HazardReport;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\ValidationException;

class HazardReportController extends Controller
{
    /**
     * GET /api/hazards - Obtener todos los peligros
     * Opcionalmente filtrar por ubicación, riesgo, o solo no-archivados
     */
    public function index(Request $request): JsonResponse
    {
        Log::info('Hazard API index request', [
            'user_id' => $request->user()?->id,
            'include_archived' => $request->query('include_archived'),
            'risk_level' => $request->query('risk_level'),
            'latitude' => $request->query('latitude'),
            'longitude' => $request->query('longitude'),
            'radius_km' => $request->query('radius_km'),
            'page' => $request->query('page', 1),
            'per_page' => $request->query('per_page', 50),
        ]);

        // Los peligros son globales y deben ser visibles para todos.
        $query = HazardReport::with([
            'comments',
            'comments.user',
            'riskLevel',
            'category',
            'estimatedDuration',
        ]);

        // Filtro por ubicación (nearby)
        if ($request->has(['latitude', 'longitude'])) {
            $latitude = (float) $request->query('latitude');
            $longitude = (float) $request->query('longitude');
            $radiusKm = (float) $request->query('radius_km', 5);
            $query->nearby($latitude, $longitude, $radiusKm);
        }

        // Filtro por nivel de riesgo
        if ($request->has('risk_level')) {
            $query->byRiskLevel($request->query('risk_level'));
        }

        // Filtro por estado (excluir archivados por defecto)
        if (!$request->query('include_archived')) {
            $query->where('status', '!=', 'archived');
        }

        // Parámetros de paginación
        $perPage = min((int) $request->query('per_page', 50), 100);
        $page = (int) $request->query('page', 1);

        $hazards = $query->orderBy('last_modified_at', 'desc')
                         ->paginate($perPage, ['*'], 'page', $page);

        Log::info('Hazard API index response', [
            'returned_count' => count($hazards->items()),
            'total' => $hazards->total(),
            'current_page' => $hazards->currentPage(),
            'last_page' => $hazards->lastPage(),
        ]);

        return response()->json([
            'success' => true,
            'data' => array_map(fn (HazardReport $hazard) => $this->formatHazard($hazard), $hazards->items()),
            'pagination' => [
                'total' => $hazards->total(),
                'per_page' => $hazards->perPage(),
                'current_page' => $hazards->currentPage(),
                'last_page' => $hazards->lastPage(),
            ],
        ]);
    }

    /**
     * POST /api/hazards - Crear un nuevo peligro
     */
    public function store(Request $request): JsonResponse
    {
        $userId = $request->user()?->id;

        $validated = $request->validate([
            'incident_latitude' => 'required|numeric|between:-90,90',
            'incident_longitude' => 'required|numeric|between:-180,180',
            'impact_radius_meters' => 'required|numeric|min:10|max:10000',
            'risk_level_code' => 'required|string|max:32',
            'category_code' => 'nullable|string|max:64',
            'estimated_duration_code' => 'nullable|string|max:64',
            'description' => 'nullable|string|max:500',
            'narrative_description' => 'nullable|string|max:500',
            'reported_at' => 'nullable|date',
            'evidence_photo_url' => 'nullable|string|max:500',
            'reported_by_username' => 'nullable|string|max:100',
            'local_id' => 'required|string|unique:hazard_reports,local_id',
        ]);

        $validated['risk_level_code'] = $this->normalizeRiskCode($validated['risk_level_code'] ?? null);
        $validated['category_code'] = $this->normalizeCategoryCode($validated['category_code'] ?? null);
        $validated['estimated_duration_code'] = $this->normalizeDurationCode($validated['estimated_duration_code'] ?? null);
        $validated['narrative_description'] = $validated['narrative_description'] ?? ($validated['description'] ?? null);
        $validated['description'] = $validated['description'] ?? $validated['narrative_description'];
        $validated['reported_by_username'] = $validated['reported_by_username'] ?? $request->user()?->name ?? 'Anónimo';

        $validated['status'] = 'created';
        $validated['last_modified_at'] = now();
        $validated['user_id'] = $userId;

        $hazard = HazardReport::create($validated);
        $hazard->update([
            'remote_id' => $hazard->remote_id ?? (string) $hazard->id,
        ]);

        if ($request->has('comments')) {
            $this->syncHazardComments($hazard, (array) $request->input('comments', []));
        }
        $hazard->load(['comments', 'comments.user', 'riskLevel', 'category', 'estimatedDuration']);

        Log::info('Hazard API store created', [
            'id' => $hazard->id,
            'local_id' => $hazard->local_id,
            'risk_level_code' => $hazard->risk_level_code,
            'status' => $hazard->status,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Peligro creado exitosamente',
            'data' => $this->formatHazard($hazard),
        ], 201);
    }

    /**
     * GET /api/hazards/{id} - Obtener un peligro específico
     */
    public function show(HazardReport $hazardReport): JsonResponse
    {
        $hazardReport->load(['comments', 'comments.user', 'riskLevel', 'category', 'estimatedDuration']);

        return response()->json([
            'success' => true,
            'data' => $this->formatHazard($hazardReport),
        ]);
    }

    /**
     * PUT /api/hazards/{id} - Actualizar un peligro
     */
    public function update(Request $request, HazardReport $hazardReport): JsonResponse
    {
        $userId = $request->user()?->id;

        if ($userId && $hazardReport->user_id !== null && (int) $hazardReport->user_id !== (int) $userId) {
            return response()->json([
                'success' => false,
                'message' => 'No autorizado',
            ], 403);
        }

        $validated = $request->validate([
            'incident_latitude' => 'numeric|between:-90,90',
            'incident_longitude' => 'numeric|between:-180,180',
            'impact_radius_meters' => 'numeric|min:10|max:10000',
            'risk_level_code' => 'string|max:32',
            'category_code' => 'nullable|string|max:64',
            'estimated_duration_code' => 'nullable|string|max:64',
            'description' => 'nullable|string|max:500',
            'narrative_description' => 'nullable|string|max:500',
            'reported_at' => 'nullable|date',
            'evidence_photo_url' => 'nullable|string|max:500',
            'reported_by_username' => 'nullable|string|max:100',
            'last_modified_at' => 'date_format:Y-m-d H:i:s',
        ]);

        if (array_key_exists('risk_level_code', $validated)) {
            $validated['risk_level_code'] = $this->normalizeRiskCode($validated['risk_level_code']);
        }
        if (array_key_exists('category_code', $validated)) {
            $validated['category_code'] = $this->normalizeCategoryCode($validated['category_code']);
        }
        if (array_key_exists('estimated_duration_code', $validated)) {
            $validated['estimated_duration_code'] = $this->normalizeDurationCode($validated['estimated_duration_code']);
        }
        if (array_key_exists('narrative_description', $validated) && !array_key_exists('description', $validated)) {
            $validated['description'] = $validated['narrative_description'];
        }
        if (array_key_exists('description', $validated) && !array_key_exists('narrative_description', $validated)) {
            $validated['narrative_description'] = $validated['description'];
        }

        // Resolución de conflictos: verificar si la actualización remota es más nueva
        if (isset($validated['last_modified_at'])) {
            $remoteTimestamp = Carbon::parse($validated['last_modified_at']);
            if ($remoteTimestamp->lessThan($hazardReport->last_modified_at)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Conflicto: versión local es más nueva (last_write_wins)',
                    'data' => $hazardReport,
                ], 409);
            }
            $validated['last_modified_at'] = $remoteTimestamp;
        } else {
            $validated['last_modified_at'] = now();
        }

        $hazardReport->update($validated);
        if ($request->has('comments')) {
            $this->syncHazardComments($hazardReport, (array) $request->input('comments', []));
        }
        $hazardReport->load(['comments', 'comments.user', 'riskLevel', 'category', 'estimatedDuration']);

        return response()->json([
            'success' => true,
            'message' => 'Peligro actualizado exitosamente',
            'data' => $this->formatHazard($hazardReport),
        ]);
    }

    /**
     * DELETE /api/hazards/{id} - Marcar peligro como archivado
     */
    public function destroy(HazardReport $hazardReport): JsonResponse
    {
        $userId = request()->user()?->id;

        if ($userId && $hazardReport->user_id !== null && (int) $hazardReport->user_id !== (int) $userId) {
            return response()->json([
                'success' => false,
                'message' => 'No autorizado',
            ], 403);
        }

        $hazardReport->update([
            'status' => 'archived',
            'last_modified_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Peligro archivado exitosamente',
        ]);
    }

    /**
     * POST /api/hazards/sync - Sincronizar peligros locales sin sincronizar
     * Recibe un array de peligros locales y los sincroniza con la BD global
     */
    public function sync(Request $request): JsonResponse
    {
        $userId = $request->user()?->id;

        try {
            $validated = $request->validate([
                'hazards' => 'required|array',
                'hazards.*.local_id' => 'required|string',
                'hazards.*.incident_latitude' => 'required|numeric|between:-90,90',
                'hazards.*.incident_longitude' => 'required|numeric|between:-180,180',
                'hazards.*.impact_radius_meters' => 'required|numeric|min:10|max:10000',
                'hazards.*.risk_level_code' => 'required|string|max:32',
                'hazards.*.category_code' => 'nullable|string|max:64',
                'hazards.*.estimated_duration_code' => 'nullable|string|max:64',
                'hazards.*.description' => 'nullable|string|max:500',
                'hazards.*.narrative_description' => 'nullable|string|max:500',
                'hazards.*.reported_at' => 'nullable|date',
                'hazards.*.evidence_photo_url' => 'nullable|string|max:500',
                'hazards.*.reported_by_username' => 'nullable|string|max:100',
                'hazards.*.last_modified_at' => 'required|date_format:Y-m-d H:i:s',
                'hazards.*.comments' => 'sometimes|array',
                'hazards.*.comments.*.author_username' => 'nullable|string|max:100',
                'hazards.*.comments.*.author_avatar_url' => 'nullable|string|max:500',
                'hazards.*.comments.*.is_anonymous' => 'nullable|boolean',
                'hazards.*.comments.*.comment_text' => 'nullable|string|max:2000',
                'hazards.*.comments.*.created_at' => 'nullable',
            ]);
        } catch (ValidationException $e) {
            Log::warning('Hazard API sync validation failed', [
                'errors' => $e->errors(),
                'payload' => $request->all(),
            ]);

            throw $e;
        }

        $syncResults = [
            'synced' => 0,
            'conflicts' => 0,
            'errors' => 0,
            'details' => [],
        ];

        Log::info('Hazard API sync request received', [
            'items' => count($validated['hazards']),
            'local_ids' => array_map(
                fn ($hazard) => $hazard['local_id'] ?? 'unknown',
                $validated['hazards']
            ),
                'user_id' => $userId,
        ]);

        foreach ($validated['hazards'] as $hazardData) {
            try {
                $hazardData['risk_level_code'] = $this->normalizeRiskCode($hazardData['risk_level_code'] ?? null);
                $hazardData['category_code'] = $this->normalizeCategoryCode($hazardData['category_code'] ?? null);
                $hazardData['estimated_duration_code'] = $this->normalizeDurationCode($hazardData['estimated_duration_code'] ?? null);
                $hazardData['narrative_description'] = $hazardData['narrative_description'] ?? ($hazardData['description'] ?? null);
                $hazardData['description'] = $hazardData['description'] ?? $hazardData['narrative_description'];
                $hazardData['reported_by_username'] = $hazardData['reported_by_username'] ?? 'Anónimo';
                $hasComments = array_key_exists('comments', $hazardData);
                $commentsData = $hasComments ? (array) $hazardData['comments'] : [];

                // Buscar si ya existe este peligro localmente
                $existing = HazardReport::query()
                    ->where(function ($query) use ($hazardData): void {
                        if (!empty($hazardData['remote_id'])) {
                            $query->where('remote_id', $hazardData['remote_id'])
                                  ->orWhere('id', $hazardData['remote_id']);
                        }
                        $query->orWhere('local_id', $hazardData['local_id']);
                    })
                    ->first();
                $remoteTimestamp = Carbon::parse($hazardData['last_modified_at']);

                if ($existing) {
                    // Resolver conflicto: comparar timestamps
                    if ($remoteTimestamp->greaterThan($existing->last_modified_at)) {
                        // El remoto es más nuevo, actualizar
                        $existing->update(array_merge(
                            $hazardData,
                            [
                                'status' => 'synced',
                                'remote_id' => $hazardData['remote_id'] ?? $existing->remote_id,
                                'synced_at' => now(),
                                'user_id' => $existing->user_id ?? $userId,
                            ]
                        ));
                        if ($hasComments) {
                            $this->syncHazardComments($existing, $commentsData);
                        }
                        $syncResults['synced']++;
                        Log::info('Hazard API sync updated existing', [
                            'local_id' => $hazardData['local_id'],
                            'id' => $existing->id,
                            'status' => 'synced',
                        ]);
                    } else {
                        // El local es más nuevo o igual, no actualizar
                        $syncResults['conflicts']++;
                        $syncResults['details'][] = [
                            'local_id' => $hazardData['local_id'],
                            'status' => 'conflict',
                            'reason' => 'Local version is newer or equal',
                        ];

                        Log::warning('Hazard API sync conflict', [
                            'local_id' => $hazardData['local_id'],
                            'existing_id' => $existing->id,
                            'remote_last_modified_at' => $hazardData['last_modified_at'],
                            'local_last_modified_at' => optional($existing->last_modified_at)->toDateTimeString(),
                        ]);
                    }
                } else {
                    // No existe, crear nuevo
                    $created = HazardReport::create(array_merge(
                        $hazardData,
                        [
                            'status' => 'synced',
                            'remote_id' => $hazardData['remote_id'] ?? null,
                            'synced_at' => now(),
                            'user_id' => $userId,
                        ]
                    ));
                    $created->update([
                        'remote_id' => $created->remote_id ?? (string) $created->id,
                    ]);
                    if ($hasComments) {
                        $this->syncHazardComments($created, $commentsData);
                    }
                    $syncResults['synced']++;

                    Log::info('Hazard API sync created new', [
                        'local_id' => $hazardData['local_id'],
                        'id' => $created->id,
                        'status' => 'synced',
                    ]);
                }
            } catch (\Exception $e) {
                $syncResults['errors']++;
                $syncResults['details'][] = [
                    'local_id' => $hazardData['local_id'] ?? 'unknown',
                    'status' => 'error',
                    'error' => $e->getMessage(),
                ];

                Log::error('Hazard API sync item error', [
                    'local_id' => $hazardData['local_id'] ?? 'unknown',
                    'error' => $e->getMessage(),
                ]);
            }
        }

        Log::info('Hazard API sync completed', [
            'synced' => $syncResults['synced'],
            'conflicts' => $syncResults['conflicts'],
            'errors' => $syncResults['errors'],
        ]);

        return response()->json([
            'success' => true,
            'message' => sprintf(
                'Sincronización completada: %d sincronizados, %d conflictos, %d errores',
                $syncResults['synced'],
                $syncResults['conflicts'],
                $syncResults['errors']
            ),
            'sync_results' => $syncResults,
        ]);
    }

    public function comments(HazardReport $hazardReport): JsonResponse
    {
        $hazardReport->load(['comments', 'comments.user', 'riskLevel', 'category', 'estimatedDuration']);

        return response()->json([
            'success' => true,
            'data' => $hazardReport->comments->map(fn (HazardComment $comment) => $this->formatComment($comment))->values(),
        ]);
    }

    public function storeComment(Request $request, HazardReport $hazardReport): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'comment_text' => ['required', 'string', 'max:2000'],
            'author_name' => ['nullable', 'string', 'max:100'],
            'author_avatar_url' => ['nullable', 'string', 'max:500'],
            'is_anonymous' => ['sometimes', 'boolean'],
            'created_at' => ['nullable'],
        ]);

        $isAnonymous = (bool) ($validated['is_anonymous'] ?? false);
        $authorName = trim((string) ($validated['author_name'] ?? ''));
        if ($authorName === '') {
            $authorName = $user && !$isAnonymous ? $user->name : 'Anónimo';
        }

        $commentedAt = $this->parseCommentTimestamp($validated['created_at'] ?? null);

        $payload = [
            'hazard_report_id' => $hazardReport->id,
            'user_id' => $user && !$isAnonymous ? $user->id : null,
            'author_name' => $authorName,
            'author_avatar_url' => $validated['author_avatar_url'] ?? null,
            'is_anonymous' => $isAnonymous || $user === null,
            'comment_text' => $validated['comment_text'],
            'commented_at' => $commentedAt,
            'last_modified_at' => $commentedAt,
            'synced_at' => now(),
        ];
        $payload['content_hash'] = HazardComment::makeContentHash($payload);

        $comment = HazardComment::updateOrCreate(
            [
                'hazard_report_id' => $hazardReport->id,
                'content_hash' => $payload['content_hash'],
            ],
            $payload
        );

        $hazardReport->update([
            'last_modified_at' => now(),
        ]);

        $hazardReport->load(['comments', 'comments.user']);

        return response()->json([
            'success' => true,
            'message' => 'Comentario agregado exitosamente',
            'data' => $this->formatComment($comment),
        ], 201);
    }

    /**
     * GET /api/hazards/unsynced - Obtener peligros locales no sincronizados
     * Para que el cliente pueda ver qué necesita sincronizar
     */
    public function getUnsynced(): JsonResponse
    {
        $unsynced = HazardReport::query()
            ->unsynced()
            ->get();

        return response()->json([
            'success' => true,
            'count' => $unsynced->count(),
            'data' => $unsynced,
        ]);
    }

    private function normalizeRiskCode(?string $value): string
    {
        $normalized = strtolower(trim((string) $value));
        if (in_array($normalized, ['low', 'medium', 'high', 'undefined'], true)) {
            return $normalized;
        }

        if (in_array($normalized, ['unknown', 'unspecified', ''], true)) {
            return 'undefined';
        }

        return 'undefined';
    }

    private function normalizeCategoryCode(?string $value): string
    {
        $normalized = strtolower(trim((string) $value));
        if (in_array($normalized, [
            'contagious_disease',
            'stagnant_water',
            'waste_accumulation',
            'aggressive_animals',
            'undefined',
        ], true)) {
            return $normalized;
        }

        if (in_array($normalized, ['unknown', 'unspecified', ''], true)) {
            return 'undefined';
        }

        return 'undefined';
    }

    private function normalizeDurationCode(?string $value): string
    {
        $normalized = strtolower(trim((string) $value));
        if (in_array($normalized, [
            '1_day',
            '3_days',
            '1_week',
            '2_weeks',
            '1_month',
            '3_months',
            '6_months',
            '1_year',
            'undefined',
        ], true)) {
            return $normalized;
        }

        if (in_array($normalized, ['unknown', 'unspecified', ''], true)) {
            return 'undefined';
        }

        return 'undefined';
    }

    private function syncHazardComments(HazardReport $hazardReport, array $commentsData): void
    {
        if ($commentsData === []) {
            return;
        }

        foreach ($commentsData as $commentData) {
            if (!is_array($commentData)) {
                continue;
            }

            $commentText = trim((string) ($commentData['comment_text'] ?? ''));
            if ($commentText === '') {
                continue;
            }

            $authorName = trim((string) ($commentData['author_username'] ?? $commentData['author_name'] ?? ''));
            $commentedAt = $commentData['created_at'] ?? $commentData['commented_at'] ?? null;
            $commentedAtValue = $this->parseCommentTimestamp($commentedAt);
            $isAnonymous = (bool) ($commentData['is_anonymous'] ?? ($authorName === '' || $authorName === 'Anónimo'));

            $payload = [
                'hazard_report_id' => $hazardReport->id,
                'user_id' => $commentData['user_id'] ?? null,
                'author_name' => $authorName !== '' ? $authorName : 'Anónimo',
                'author_avatar_url' => $commentData['author_avatar_url'] ?? null,
                'is_anonymous' => $isAnonymous,
                'comment_text' => $commentText,
                'commented_at' => $commentedAtValue,
                'last_modified_at' => now(),
                'synced_at' => now(),
            ];
            $payload['content_hash'] = HazardComment::makeContentHash($payload);

            $existingByHash = HazardComment::query()
                ->where('hazard_report_id', $hazardReport->id)
                ->where('content_hash', $payload['content_hash'])
                ->first();

            if ($existingByHash) {
                $existingByHash->update($payload);
                continue;
            }

            $equivalent = $this->findEquivalentComment($hazardReport->id, $payload);
            if ($equivalent) {
                // Conservar el hash histórico evita crear duplicados para datos previos.
                $payload['content_hash'] = $equivalent->content_hash;
                $equivalent->update($payload);
                continue;
            }

            HazardComment::create($payload);
        }

        $this->pruneDuplicateComments($hazardReport->id);

        $hazardReport->update([
            'last_modified_at' => now(),
        ]);
    }

    private function formatComment(HazardComment $comment): array
    {
        return [
            'id' => $comment->id,
            'hazard_report_id' => $comment->hazard_report_id,
            'user_id' => $comment->user_id,
            'author_username' => $comment->author_name,
            'author_avatar_url' => $comment->author_avatar_url,
            'is_anonymous' => $comment->is_anonymous,
            'comment_text' => $comment->comment_text,
            'created_at' => optional($comment->commented_at ?? $comment->created_at)?->toIso8601String(),
            'last_modified_at' => optional($comment->last_modified_at)?->toIso8601String(),
        ];
    }

    private function formatHazard(HazardReport $hazard): array
    {
        return [
            'id' => $hazard->id,
            'incident_latitude' => $hazard->incident_latitude,
            'incident_longitude' => $hazard->incident_longitude,
            'impact_radius_meters' => $hazard->impact_radius_meters,
            'risk_level_code' => $hazard->risk_level_code,
            'category_code' => $hazard->category_code,
            'estimated_duration_code' => $hazard->estimated_duration_code,
            'description' => $hazard->description,
            'narrative_description' => $hazard->narrative_description,
            'reported_at' => optional($hazard->reported_at)?->toIso8601String(),
            'evidence_photo_url' => $hazard->evidence_photo_url,
            'reported_by_username' => $hazard->reported_by_username,
            'user_id' => $hazard->user_id,
            'status' => $hazard->status,
            'local_id' => $hazard->local_id,
            'remote_id' => $hazard->remote_id,
            'last_modified_at' => optional($hazard->last_modified_at)?->toIso8601String(),
            'synced_at' => optional($hazard->synced_at)?->toIso8601String(),
            'comments_json' => $hazard->comments_json,
        ];
    }

    private function parseCommentTimestamp(mixed $value): Carbon
    {
        if ($value instanceof Carbon) {
            return $value;
        }

        if (is_int($value) || is_float($value) || (is_string($value) && ctype_digit($value))) {
            return Carbon::createFromTimestampMs((int) $value);
        }

        if (is_string($value) && trim($value) !== '') {
            return Carbon::parse($value);
        }

        return now();
    }

    private function findEquivalentComment(int $hazardId, array $payload): ?HazardComment
    {
        $query = HazardComment::query()
            ->where('hazard_report_id', $hazardId)
            ->where('author_name', (string) ($payload['author_name'] ?? ''))
            ->where('is_anonymous', (bool) ($payload['is_anonymous'] ?? false))
            ->where('comment_text', (string) ($payload['comment_text'] ?? ''));

        if (array_key_exists('user_id', $payload) && $payload['user_id'] !== null) {
            $query->where('user_id', (int) $payload['user_id']);
        } else {
            $query->whereNull('user_id');
        }

        $commentedAt = $payload['commented_at'] ?? null;
        if ($commentedAt instanceof Carbon) {
            $start = $commentedAt->copy()->startOfSecond();
            $end = $start->copy()->addSecond();
            $query->whereBetween('commented_at', [$start, $end]);
        }

        return $query->orderBy('id')->first();
    }

    private function pruneDuplicateComments(int $hazardId): void
    {
        $seen = [];

        $comments = HazardComment::query()
            ->where('hazard_report_id', $hazardId)
            ->orderBy('id')
            ->get();

        foreach ($comments as $comment) {
            $key = implode('|', [
                $hazardId,
                $comment->user_id ?? 'null',
                $comment->author_name,
                (int) $comment->is_anonymous,
                $comment->comment_text,
                optional($comment->commented_at)->format('Y-m-d H:i:s') ?? '',
            ]);

            if (isset($seen[$key])) {
                $comment->delete();
                continue;
            }

            $seen[$key] = true;
        }
    }
}
