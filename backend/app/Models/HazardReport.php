<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphMany;

class HazardReport extends Model
{
    protected $fillable = [
        'incident_latitude',
        'incident_longitude',
        'impact_radius_meters',
        'risk_level_id',
        'category_id',
        'estimated_duration_id',
        'risk_level_code',
        'category_code',
        'estimated_duration_code',
        'description',
        'narrative_description',
        'reported_at',
        'evidence_photo_url',
        'reported_by_username',
        'user_id',
        'status',
        'local_id',
        'remote_id',
        'last_modified_at',
        'synced_at',
    ];

    protected $casts = [
        'incident_latitude' => 'float',
        'incident_longitude' => 'float',
        'impact_radius_meters' => 'float',
        'risk_level_id' => 'integer',
        'category_id' => 'integer',
        'estimated_duration_id' => 'integer',
        'reported_at' => 'datetime',
        'last_modified_at' => 'datetime',
        'synced_at' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    protected $appends = [
        'risk_level_code',
        'category_code',
        'estimated_duration_code',
        'comments_json',
    ];

    /**
     * Relación con User (puede ser null)
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function comments(): MorphMany
    {
        return $this->morphMany(ReportComment::class, 'commentable')->orderBy('commented_at')->orderBy('id');
    }

    public function riskLevel(): BelongsTo
    {
        return $this->belongsTo(HazardRiskLevel::class, 'risk_level_id');
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(HazardCategory::class, 'category_id');
    }

    public function estimatedDuration(): BelongsTo
    {
        return $this->belongsTo(HazardEstimatedDuration::class, 'estimated_duration_id');
    }

    public function getRiskLevelCodeAttribute(): string
    {
        return (string) ($this->riskLevel?->code ?? 'undefined');
    }

    public function getCategoryCodeAttribute(): string
    {
        return (string) ($this->category?->code ?? 'undefined');
    }

    public function getEstimatedDurationCodeAttribute(): string
    {
        return (string) ($this->estimatedDuration?->code ?? 'undefined');
    }

    public function setRiskLevelCodeAttribute(?string $value): void
    {
        $code = $this->normalizeCode((string) $value, ['low', 'medium', 'high', 'undefined']);
        $this->attributes['risk_level_id'] = HazardRiskLevel::idByCode($code);
    }

    public function setCategoryCodeAttribute(?string $value): void
    {
        $normalized = strtolower(trim((string) $value));
        if ($normalized === 'aggressive_animals') {
            $normalized = 'possible_rabies_vectors';
        } elseif ($normalized === '' || in_array($normalized, ['unknown', 'unspecified', 'undefined'], true)) {
            $normalized = 'pest_presence';
        }

        $code = in_array($normalized, [
            'contagious_disease',
            'stagnant_water',
            'waste_accumulation',
            'pest_presence',
            'possible_rabies_vectors',
        ], true) ? $normalized : 'pest_presence';
        $this->attributes['category_id'] = HazardCategory::idByCode($code);
    }

    public function setEstimatedDurationCodeAttribute(?string $value): void
    {
        $code = $this->normalizeCode((string) $value, [
            '1_day',
            '3_days',
            '1_week',
            '2_weeks',
            '1_month',
            '3_months',
            '6_months',
            '1_year',
            'undefined',
        ]);
        $this->attributes['estimated_duration_id'] = HazardEstimatedDuration::idByCode($code);
    }

    public function getCommentsJsonAttribute(): string
    {
        $comments = $this->relationLoaded('comments')
            ? $this->comments
            : $this->comments()->get();

        return $comments->values()->map(static function (ReportComment $comment): array {
            $commentedAt = $comment->commented_at ?? $comment->created_at ?? now();
            $timestampMs = ($commentedAt->getTimestamp() * 1000)
                + (int) floor(((int) $commentedAt->format('u')) / 1000);

            return [
                'author_username' => $comment->author_name,
                'author_avatar_url' => $comment->author_avatar_url,
                'is_anonymous' => $comment->is_anonymous,
                'comment_text' => $comment->comment_text,
                'created_at' => $timestampMs,
            ];
        })->toJson();
    }

    /**
     * Determina si el peligro es local (no sincronizado)
     */
    public function isLocal(): bool
    {
        return $this->status === 'created' && $this->remote_id === null;
    }

    /**
     * Determina si el peligro está sincronizado
     */
    public function isSynced(): bool
    {
        return $this->status === 'synced' && $this->remote_id !== null;
    }

    /**
     * Marca el peligro como sincronizado
     */
    public function markAsSynced(string $remoteId): void
    {
        $this->update([
            'status' => 'synced',
            'remote_id' => $remoteId,
            'synced_at' => now(),
        ]);
    }

    /**
     * Actualiza el timestamp de última modificación
     */
    public function touchLastModified(): void
    {
        $this->update([
            'last_modified_at' => now(),
        ]);
    }

    /**
     * Scope para obtener peligros no sincronizados
     */
    public function scopeUnsynced($query)
    {
        return $query->where(function ($builder): void {
            $builder->where('status', '=', 'created')
                ->orWhereColumn('synced_at', '<', 'updated_at');
        });
    }

    /**
     * Scope para obtener peligros sincronizados
     */
    public function scopeSynced($query)
    {
        return $query->where('status', '=', 'synced');
    }

    /**
     * Scope para obtener peligros dentro de un rango geográfico
     */
    public function scopeNearby($query, float $latitude, float $longitude, float $radiusKm = 5)
    {
        // Conversión aproximada de km a grados (1 grado ≈ 111 km)
        $latDelta = $radiusKm / 111.0;
        $lonDelta = $radiusKm / (111.0 * cos(deg2rad($latitude)));

        return $query->whereBetween('incident_latitude', [$latitude - $latDelta, $latitude + $latDelta])
            ->whereBetween('incident_longitude', [$longitude - $lonDelta, $longitude + $lonDelta]);
    }

    /**
     * Scope para obtener peligros por nivel de riesgo
     */
    public function scopeByRiskLevel($query, string $riskLevel)
    {
        $normalizedRisk = $this->normalizeCode($riskLevel, ['low', 'medium', 'high', 'undefined']);

        return $query->whereHas('riskLevel', function ($builder) use ($normalizedRisk): void {
            $builder->where('code', '=', $normalizedRisk);
        });
    }

    /**
     * Resuelve conflictos usando "last write wins"
     * Retorna true si este hazard gana, false si el otro gana
     */
    public function resolvesConflictWith(HazardReport $other): bool
    {
        // El que tiene timestamp más reciente gana
        return $this->last_modified_at->greaterThanOrEqualTo($other->last_modified_at);
    }

    private function normalizeCode(string $value, array $allowed): string
    {
        $normalized = strtolower(trim($value));
        if ($normalized === '' || $normalized === 'unknown' || $normalized === 'unspecified') {
            return 'undefined';
        }

        return in_array($normalized, $allowed, true) ? $normalized : 'undefined';
    }
}
