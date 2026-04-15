<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Carbon\Carbon;

class HazardReport extends Model
{
    protected $fillable = [
        'incident_latitude',
        'incident_longitude',
        'impact_radius_meters',
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
        'reported_at' => 'datetime',
        'last_modified_at' => 'datetime',
        'synced_at' => 'datetime',
        'created_at' => 'datetime',
        'updated_at' => 'datetime',
    ];

    /**
     * Relación con User (puede ser null)
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
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
        return $query->where('status', '=', 'created')
                     ->orWhereColumn('synced_at', '<', 'updated_at');
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
        return $query->where('risk_level_code', '=', $riskLevel);
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
}
