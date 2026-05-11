<?php

namespace Tests\F1\Services;

use App\Models\FoundPetReport;
use App\Models\GenericReport;
use App\Models\LostPetReport;
use App\Models\Pet;
use App\Models\ReportComment;
use App\Models\User;
use App\Services\Comments\ReportCommentService;
use App\Services\Reports\FoundPetReportService;
use App\Services\Reports\GenericReportService;
use App\Services\Reports\LostPetReportService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * F1-021/F1-023: White-box coverage for report domain services.
 */
class ReportServicesTest extends TestCase
{
    use RefreshDatabase;

    /**
     * F1-021: GenericReportService covers store, update, delete, permissions and pagination.
     */
    public function test_generic_report_service_store_update_delete_and_permissions(): void
    {
        $service = new GenericReportService(new ReportCommentService());
        $user = User::factory()->create();

        $report = $service->store($user->id, [
            'latitude' => 4.71,
            'longitude' => -74.07,
            'description' => 'Reporte generico',
            'reported_date' => '2026-05-08 09:00:00',
            'risk_level_code' => 'not-valid',
            'impact_radius_meters' => 24.6,
            'photo_url' => 'generic/photo.png',
        ]);

        $this->assertInstanceOf(GenericReport::class, $report);
        $this->assertSame('undefined', $report->risk_level_code);
        $this->assertSame(25, $report->impact_radius_meters);
        $this->assertTrue($service->canMutate($user->id, $report));
        $this->assertFalse($service->canMutate(null, $report));
        $this->assertFalse($service->canMutate(User::factory()->create()->id, $report));

        $updated = $service->update($report, [
            'latitude' => 4.72,
            'longitude' => -74.08,
            'description' => 'Actualizado',
            'reported_date' => '2026-05-08 10:00:00',
            'risk_level_code' => 'HIGH',
            'impact_radius_meters' => -10,
        ]);

        $this->assertSame('high', $updated->risk_level_code);
        $this->assertSame(0, $updated->impact_radius_meters);
        $this->assertGreaterThanOrEqual(1, $service->paginate(false, 10, 1)->total());

        $comment = ReportComment::create([
            'commentable_type' => $report->getMorphClass(),
            'commentable_id' => $report->id,
            'author_name' => 'QA',
            'is_anonymous' => true,
            'comment_text' => 'Se elimina con reporte',
            'commented_at' => now(),
            'content_hash' => ReportComment::makeContentHash([
                'commentable_type' => $report->getMorphClass(),
                'commentable_id' => $report->id,
                'author_name' => 'QA',
                'is_anonymous' => true,
                'comment_text' => 'Se elimina con reporte',
                'commented_at' => now(),
            ]),
        ]);
        $service->delete($report);

        $this->assertDatabaseMissing('generic_reports', ['id' => $report->id]);
        $this->assertDatabaseMissing('report_comments', ['id' => $comment->id]);
    }

    /**
     * F1-022: LostPetReportService covers store, update, duplicate guard, delete and permissions.
     */
    public function test_lost_pet_report_service_store_update_duplicate_guard_delete_and_permissions(): void
    {
        $service = new LostPetReportService(new ReportCommentService());
        $user = User::factory()->create();
        $pet = Pet::factory()->create(['user_id' => $user->id, 'status' => 'normal']);

        $report = $service->store($user->id, [
            'pet_id' => $pet->id,
            'last_seen_latitude' => 4.71,
            'last_seen_longitude' => -74.07,
            'details' => 'Perdida',
            'disappearance_date' => '2026-05-08 09:00:00',
            'photo_url' => 'lost/photo.png',
            'phone' => '300',
        ]);

        $this->assertInstanceOf(LostPetReport::class, $report);
        $this->assertSame('perdida', $pet->refresh()->status);
        $this->assertTrue($service->canMutate($user->id, $report));
        $this->assertFalse($service->canMutate(null, $report));

        $updated = $service->update($report, [
            'pet_id' => $pet->id,
            'last_seen_latitude' => 4.72,
            'last_seen_longitude' => -74.08,
            'details' => 'Perdida actualizada',
            'disappearance_date' => '2026-05-08 10:00:00',
            'phone' => '301',
        ]);
        $this->assertSame('Perdida actualizada', $updated->details);

        $this->postJson('/api/lost-pet-reports', [
            'pet_id' => $pet->id,
            'last_seen_latitude' => 4.72,
            'last_seen_longitude' => -74.08,
            'details' => 'Duplicada',
            'disappearance_date' => '2026-05-08 10:00:00',
            'phone' => '301',
        ])->assertStatus(401);

        $service->delete($report);
        $this->assertSame('normal', $pet->refresh()->status);
        $this->assertDatabaseMissing('lost_pet_reports', ['id' => $report->id]);
    }

    /**
     * F1-023: FoundPetReportService covers linked and ownerless pet contexts.
     */
    public function test_found_pet_report_service_store_update_delete_and_pet_contexts(): void
    {
        $service = new FoundPetReportService(new ReportCommentService());
        $owner = User::factory()->create();
        $finder = User::factory()->create();
        $pet = Pet::factory()->create(['user_id' => $owner->id, 'status' => 'perdida']);
        $lost = LostPetReport::create([
            'user_id' => $owner->id,
            'pet_id' => $pet->id,
            'last_seen_latitude' => 4.71,
            'last_seen_longitude' => -74.07,
            'details' => 'Perdida',
            'disappearance_date' => now(),
            'phone' => '300',
        ]);

        $linked = $service->store($finder->id, [
            'matched_lost_pet_report_id' => $lost->id,
            'latitude' => 4.72,
            'longitude' => -74.08,
            'details' => 'Encontrada vinculada',
            'found_date' => '2026-05-08 11:00:00',
            'phone' => '301',
        ]);

        $this->assertInstanceOf(FoundPetReport::class, $linked);
        $this->assertSame($pet->id, $linked->pet_id);
        $this->assertTrue($service->canMutate($finder->id, $linked));
        $this->assertFalse($service->canMutate($owner->id, $linked));

        $ownerless = $service->store($finder->id, [
            'latitude' => 4.73,
            'longitude' => -74.09,
            'details' => 'Sin mascota previa',
            'found_date' => '2026-05-08 12:00:00',
            'photo_url' => 'found/photo.png',
        ]);

        $this->assertTrue((bool) $ownerless->pet->is_ownerless);

        $updated = $service->update($ownerless, [
            'pet_id' => $ownerless->pet_id,
            'latitude' => 4.74,
            'longitude' => -74.10,
            'details' => 'Encontrada actualizada',
            'found_date' => '2026-05-08 13:00:00',
        ]);
        $this->assertSame('Encontrada actualizada', $updated->details);

        $this->assertGreaterThanOrEqual(2, $service->paginate(false, 10, 1)->total());
        $service->delete($linked);
        $this->assertDatabaseMissing('found_pet_reports', ['id' => $linked->id]);
    }

    /**
     * F1-021/F1-022/F1-023-extra: report service sync methods document current legacy errors.
     */
    public function test_sync_methods_document_removed_local_sync_contract_as_errors(): void
    {
        $user = User::factory()->create();

        $genericResult = (new GenericReportService(new ReportCommentService()))->sync($user->id, [[
            'local_id' => 'generic-local',
            'latitude' => 4.71,
            'longitude' => -74.07,
            'description' => 'Sync removed',
            'reported_date' => now()->toDateTimeString(),
            'risk_level_code' => 'low',
            'last_modified_at' => now()->toDateTimeString(),
        ]]);
        $this->assertSame(1, $genericResult['errors']);

        $foundResult = (new FoundPetReportService(new ReportCommentService()))->sync($user->id, [[
            'local_id' => 'found-local',
            'latitude' => 4.71,
            'longitude' => -74.07,
            'details' => 'Sync removed',
            'found_date' => now()->toDateTimeString(),
            'last_modified_at' => now()->toDateTimeString(),
        ]]);
        $this->assertSame(1, $foundResult['errors']);

        $lostResult = (new LostPetReportService(new ReportCommentService()))->sync($user->id, [[
            'local_id' => 'lost-local',
            'pet_local_uuid' => 'pet-local',
            'last_seen_latitude' => 4.71,
            'last_seen_longitude' => -74.07,
            'details' => 'Sync removed',
            'disappearance_date' => now()->toDateTimeString(),
            'phone' => '300',
            'last_modified_at' => now()->toDateTimeString(),
        ]]);
        $this->assertSame(1, $lostResult['errors']);
    }
}
