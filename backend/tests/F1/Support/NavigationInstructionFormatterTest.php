<?php

namespace Tests\F1\Support;

use App\Support\NavigationInstructionFormatter;
use Tests\TestCase;

/**
 * F1-025-extra: Direct coverage for route navigation instruction normalization.
 */
class NavigationInstructionFormatterTest extends TestCase
{
    /**
     * F1-025-extra: Complete GraphHopper instruction fields are normalized for API consumers.
     */
    public function test_normalize_maps_complete_instruction_fields(): void
    {
        $normalized = NavigationInstructionFormatter::normalize([
            [
                'sign' => '2',
                'text' => 'Gire a la derecha',
                'street_name' => 'Calle 10',
                'exit_number' => '3',
                'distance' => '125.5',
                'time' => 45000,
                'interval' => [4, 7],
            ],
        ]);

        $this->assertSame([
            [
                'sequence' => 0,
                'sign' => 2,
                'text' => 'Gire a la derecha',
                'street_name' => 'Calle 10',
                'exit_number' => 3,
                'distance_meters' => 125.5,
                'duration_seconds' => 45.0,
                'point_start_index' => 4,
                'point_end_index' => 7,
            ],
        ], $normalized);
    }

    /**
     * F1-025-extra: Missing optional instruction fields receive safe defaults.
     */
    public function test_normalize_applies_defaults_for_missing_optional_fields(): void
    {
        $normalized = NavigationInstructionFormatter::normalize([
            ['interval' => [5]],
            [],
        ]);

        $this->assertSame(0, $normalized[0]['sequence']);
        $this->assertSame(0, $normalized[0]['sign']);
        $this->assertSame('', $normalized[0]['text']);
        $this->assertNull($normalized[0]['exit_number']);
        $this->assertSame(5, $normalized[0]['point_start_index']);
        $this->assertSame(5, $normalized[0]['point_end_index']);
        $this->assertSame(1, $normalized[1]['sequence']);
        $this->assertSame(0, $normalized[1]['point_start_index']);
        $this->assertSame(0, $normalized[1]['point_end_index']);
    }
}
