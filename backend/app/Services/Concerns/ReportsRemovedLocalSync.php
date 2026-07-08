<?php

namespace App\Services\Concerns;

trait ReportsRemovedLocalSync
{
    /**
     * @param  array<int, array<string, mixed>>  $items
     * @return array<string, mixed>
     */
    protected function removedLocalSyncResult(array $items, bool $withDeleted = true, bool $withConflicts = false): array
    {
        $result = ['synced' => 0];

        if ($withDeleted) {
            $result['deleted'] = 0;
        }

        if ($withConflicts) {
            $result['conflicts'] = 0;
        }

        $result['errors'] = count($items);
        $result['details'] = array_map(static fn (array $item): array => [
            'local_id' => $item['local_id'] ?? 'unknown',
            'status' => 'error',
            'error' => 'Local sync contract removed.',
        ], $items);

        return $result;
    }
}
