<?php

namespace Tests\Unit;

use App\Support\NavigationInstructionFormatter;
use PHPUnit\Framework\TestCase;

class NavigationInstructionFormatterTest extends TestCase
{
    public function test_it_preserves_roundabout_exit_number(): void
    {
        $instructions = NavigationInstructionFormatter::normalize([
            [
                'sign' => 6,
                'text' => 'At roundabout, take exit 3',
                'street_name' => 'Avenida Central',
                'exit_number' => 3,
                'distance' => 42.5,
                'time' => 8000,
                'interval' => [12, 18],
            ],
        ]);

        $this->assertSame(3, $instructions[0]['exit_number']);
        $this->assertSame(6, $instructions[0]['sign']);
        $this->assertSame(8.0, $instructions[0]['duration_seconds']);
        $this->assertSame(12, $instructions[0]['point_start_index']);
        $this->assertSame(18, $instructions[0]['point_end_index']);
    }
}
