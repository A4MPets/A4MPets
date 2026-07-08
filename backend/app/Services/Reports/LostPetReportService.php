<?php

namespace App\Services\Reports;

use App\Models\LostPetReport;
use App\Models\Pet;
use App\Services\Comments\ReportCommentService;
use App\Services\Concerns\ReportsRemovedLocalSync;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;

class LostPetReportService
{
    use ReportsRemovedLocalSync;

    public function __construct(
        private readonly ReportCommentService $reportCommentService
    ) {}

    public function paginate(bool $includeArchived, int $perPage, int $page): LengthAwarePaginator
    {
        return LostPetReport::query()
            ->with(['pet', 'comments', 'comments.user'])
            ->orderByDesc('updated_at')
            ->paginate($perPage, ['*'], 'page', $page);
    }

    /** @param array<string, mixed> $validated */
    public function store(?int $userId, array $validated): LostPetReport
    {
        $pet = $this->resolvePetForUser($userId, (int) $validated['pet_id']);
        $this->ensureNoActiveReportForPet($pet);
        $report = LostPetReport::create($this->payload($validated, $pet, ['user_id' => $userId]));
        $pet->update(['status' => 'perdida']);

        return $report->refresh()->load(['pet', 'comments', 'comments.user']);
    }

    /** @param array<string, mixed> $validated */
    public function update(LostPetReport $report, array $validated): LostPetReport
    {
        $pet = $this->resolvePetForUser($report->user_id, (int) $validated['pet_id']);
        $this->ensureNoActiveReportForPet($pet, $report);
        $report->update($this->payload($validated, $pet));
        $pet->update(['status' => 'perdida']);

        return $report->refresh()->load(['pet', 'comments', 'comments.user']);
    }

    public function delete(LostPetReport $report): void
    {
        $report->pet?->update(['status' => 'normal']);
        $report->comments()->delete();
        $report->delete();
    }

    public function canMutate(?int $userId, LostPetReport $report): bool
    {
        return $userId !== null && (int) $report->user_id === (int) $userId;
    }

    /** @param array<int, array<string, mixed>> $reports */
    public function sync(?int $userId, array $reports): array
    {
        return $this->removedLocalSyncResult($reports);
    }

    private function resolvePetForUser(?int $userId, int $petId): Pet
    {
        return Pet::query()->where('user_id', $userId)->where('id', $petId)->firstOrFail();
    }

    /**
     * @param  array<string, mixed>  $data
     * @param  array<string, mixed>  $extra
     * @return array<string, mixed>
     */
    private function payload(array $data, Pet $pet, array $extra = []): array
    {
        return $extra + [
            'pet_id' => $pet->id,
            'pet_local_uuid' => $pet->local_uuid ?? null,
            'last_seen_latitude' => $data['last_seen_latitude'],
            'last_seen_longitude' => $data['last_seen_longitude'],
            'name' => null,
            'details' => $data['details'],
            'disappearance_date' => $data['disappearance_date'],
            'photo_url' => $data['photo_url'] ?? null,
            'phone' => $data['phone'],
        ];
    }

    private function ensureNoActiveReportForPet(Pet $pet, ?LostPetReport $currentReport = null): void
    {
        $query = LostPetReport::query()->where('pet_id', $pet->id);

        if ($currentReport !== null) {
            $query->where('id', '!=', $currentReport->id);
        }

        abort_if($query->exists(), 422, 'La mascota ya tiene un reporte de perdida activo.');
    }
}
