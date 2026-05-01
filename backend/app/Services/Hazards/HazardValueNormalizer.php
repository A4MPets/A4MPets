<?php

namespace App\Services\Hazards;

class HazardValueNormalizer
{
    public function normalizeRiskCode(?string $value): string
    {
        $normalized = strtolower(trim((string) $value));

        if (in_array($normalized, ['low', 'medium', 'high', 'undefined'], true)) {
            return $normalized;
        }

        return 'undefined';
    }

    public function normalizeCategoryCode(?string $value): string
    {
        $normalized = strtolower(trim((string) $value));

        if (in_array($normalized, [
            'contagious_disease',
            'stagnant_water',
            'waste_accumulation',
            'pest_presence',
            'possible_rabies_vectors',
        ], true)) {
            return $normalized;
        }

        if ($normalized === 'aggressive_animals') {
            return 'possible_rabies_vectors';
        }

        return 'pest_presence';
    }

    public function normalizeDurationCode(?string $value): string
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

        return 'undefined';
    }
}
