<?php

namespace App\Services\Hazards;

class HazardRoutingRiskFilter
{
    /**
     * @return array<int, string>
     */
    public function normalizeSelectedFilters(?array $filters): array
    {
        if ($filters === null) {
            return ['low', 'medium', 'high'];
        }

        $normalized = collect($filters)
            ->map(static fn ($value) => strtolower(trim((string) $value)))
            ->filter(static fn (string $value) => in_array($value, ['low', 'medium', 'high'], true))
            ->unique()
            ->values()
            ->all();

        return $normalized;
    }

    public function routingBucketForRiskCode(?string $riskLevelCode): string
    {
        $normalized = strtolower(trim((string) $riskLevelCode));

        return match ($normalized) {
            'low' => 'low',
            'medium' => 'medium',
            'high' => 'high',
            'undefined' => 'high',
            default => 'high',
        };
    }

    /**
     * @param  array<int, string>  $selectedFilters
     */
    public function shouldAvoidRisk(?string $riskLevelCode, array $selectedFilters): bool
    {
        if ($selectedFilters === []) {
            return false;
        }

        return in_array($this->routingBucketForRiskCode($riskLevelCode), $selectedFilters, true);
    }
}
