<?php

namespace Tests\F1\Services;

use App\Services\Hazards\HazardValueNormalizer;
use Tests\TestCase;

/**
 * F1-017: HazardValueNormalizer unit coverage for risk, category and duration codes.
 */
class HazardValueNormalizerTest extends TestCase
{
    private HazardValueNormalizer $normalizer;

    protected function setUp(): void
    {
        parent::setUp();
        $this->normalizer = new HazardValueNormalizer();
    }

    /**
     * F1-017: valid risk codes are accepted.
     */
    public function test_normalize_risk_code_accepts_valid_values(): void
    {
        $this->assertEquals('low', $this->normalizer->normalizeRiskCode('low'));
        $this->assertEquals('medium', $this->normalizer->normalizeRiskCode('medium'));
        $this->assertEquals('high', $this->normalizer->normalizeRiskCode('HIGH'));
        $this->assertEquals('undefined', $this->normalizer->normalizeRiskCode('undefined'));
    }

    /**
     * F1-017-extra: unknown risk codes return undefined.
     */
    public function test_normalize_risk_code_returns_undefined_for_unknown(): void
    {
        $this->assertEquals('undefined', $this->normalizer->normalizeRiskCode('critical'));
        $this->assertEquals('undefined', $this->normalizer->normalizeRiskCode(null));
        $this->assertEquals('undefined', $this->normalizer->normalizeRiskCode(''));
    }

    /**
     * F1-017: valid category codes are accepted.
     */
    public function test_normalize_category_code_accepts_valid_values(): void
    {
        $this->assertEquals('contagious_disease', $this->normalizer->normalizeCategoryCode('contagious_disease'));
        $this->assertEquals('stagnant_water', $this->normalizer->normalizeCategoryCode('stagnant_water'));
        $this->assertEquals('waste_accumulation', $this->normalizer->normalizeCategoryCode('waste_accumulation'));
        $this->assertEquals('pest_presence', $this->normalizer->normalizeCategoryCode('pest_presence'));
        $this->assertEquals('possible_rabies_vectors', $this->normalizer->normalizeCategoryCode('possible_rabies_vectors'));
    }

    /**
     * F1-017-extra: aggressive_animals is mapped to possible_rabies_vectors.
     */
    public function test_normalize_category_code_maps_aggressive_animals(): void
    {
        $this->assertEquals('possible_rabies_vectors', $this->normalizer->normalizeCategoryCode('aggressive_animals'));
    }

    /**
     * F1-017-extra: unknown category codes use pest_presence fallback.
     */
    public function test_normalize_category_code_returns_pest_presence_for_unknown(): void
    {
        $this->assertEquals('pest_presence', $this->normalizer->normalizeCategoryCode('unknown_category'));
        $this->assertEquals('pest_presence', $this->normalizer->normalizeCategoryCode(null));
    }

    /**
     * F1-017: valid duration codes are accepted.
     */
    public function test_normalize_duration_code_accepts_valid_values(): void
    {
        $this->assertEquals('1_day', $this->normalizer->normalizeDurationCode('1_day'));
        $this->assertEquals('3_days', $this->normalizer->normalizeDurationCode('3_days'));
        $this->assertEquals('1_week', $this->normalizer->normalizeDurationCode('1_week'));
        $this->assertEquals('2_weeks', $this->normalizer->normalizeDurationCode('2_weeks'));
        $this->assertEquals('1_month', $this->normalizer->normalizeDurationCode('1_month'));
        $this->assertEquals('3_months', $this->normalizer->normalizeDurationCode('3_months'));
        $this->assertEquals('6_months', $this->normalizer->normalizeDurationCode('6_months'));
        $this->assertEquals('1_year', $this->normalizer->normalizeDurationCode('1_year'));
    }

    /**
     * F1-017-extra: unknown duration codes return undefined.
     */
    public function test_normalize_duration_code_returns_undefined_for_unknown(): void
    {
        $this->assertEquals('undefined', $this->normalizer->normalizeDurationCode('5_years'));
        $this->assertEquals('undefined', $this->normalizer->normalizeDurationCode(null));
    }
}
