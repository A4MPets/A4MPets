<?php

namespace App\Support;

class NavigationInstructionFormatter
{
    /**
     * @param  array<int, array<string, mixed>>  $instructions
     * @return array<int, array<string, mixed>>
     */
    public static function normalize(array $instructions): array
    {
        $normalized = [];

        foreach (array_values($instructions) as $sequence => $instruction) {
            $interval = $instruction['interval'] ?? [0, 0];

            $normalized[] = [
                'sequence' => $sequence,
                'sign' => (int) ($instruction['sign'] ?? 0),
                'text' => (string) ($instruction['text'] ?? ''),
                'street_name' => (string) ($instruction['street_name'] ?? ''),
                'exit_number' => isset($instruction['exit_number'])
                    ? (int) $instruction['exit_number']
                    : null,
                'distance_meters' => (float) ($instruction['distance'] ?? 0.0),
                'duration_seconds' => ((float) ($instruction['time'] ?? 0.0)) / 1000.0,
                'point_start_index' => (int) ($interval[0] ?? 0),
                'point_end_index' => (int) ($interval[1] ?? ($interval[0] ?? 0)),
            ];
        }

        return $normalized;
    }
}
