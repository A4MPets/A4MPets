<?php

namespace Tests\F1\Services;

use App\Models\HazardReport;
use App\Models\User;
use App\Services\Comments\ReportCommentService;
use App\Services\Hazards\HazardReportService;
use App\Services\Hazards\HazardResponseFormatter;
use App\Services\Hazards\HazardRoutingRiskFilter;
use App\Services\Hazards\HazardValueNormalizer;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * F1-018/F1-020: Hazard domain service coverage.
 */
class HazardServicesTest extends TestCase
{
    use RefreshDatabase;

    /**
     * F1-018: HazardRoutingRiskFilter normalizes selected filters and avoidance decisions.
     */
    public function test_hazard_routing_risk_filter_normalizes_and_decides_selected_risks(): void
    {
        $filter = new HazardRoutingRiskFilter;

        $this->assertSame(['low', 'medium', 'high', 'other'], $filter->normalizeSelectedFilters(null));
        $this->assertSame(['high', 'other'], $filter->normalizeSelectedFilters(['HIGH', 'other', 'bad', 'high']));
        $this->assertSame('high', $filter->routingBucketForRiskCode('undefined'));
        $this->assertTrue($filter->shouldAvoidRisk('medium', ['medium']));
        $this->assertFalse($filter->shouldAvoidRisk('low', []));
        $this->assertTrue($filter->shouldAvoidOtherReports(['other']));
        $this->assertFalse($filter->shouldAvoidOtherReports(['high']));
    }

    /**
     * F1-019: HazardReportService covers store, update, paginate, delete and permissions.
     */
    public function test_hazard_report_service_store_update_paginate_delete_and_permissions(): void
    {
        $service = new HazardReportService(new HazardValueNormalizer, new ReportCommentService);
        $user = User::factory()->create(['name' => 'Hazard QA']);

        $hazard = $service->store([
            'incident_latitude' => 4.71,
            'incident_longitude' => -74.07,
            'impact_radius_meters' => 125,
            'risk_level_code' => 'HIGH',
            'category_code' => 'aggressive_animals',
            'estimated_duration_code' => 'bad-duration',
            'description' => 'Peligro inicial',
            'comments' => [
                ['author_name' => 'Vecino', 'comment_text' => 'Comentario inicial'],
            ],
        ], $user->id, $user->name);

        $this->assertInstanceOf(HazardReport::class, $hazard);
        $this->assertSame('high', $hazard->risk_level_code);
        $this->assertSame('possible_rabies_vectors', $hazard->category_code);
        $this->assertSame('undefined', $hazard->estimated_duration_code);
        $this->assertSame('Hazard QA', $hazard->reported_by_username);
        $this->assertSame(1, $hazard->comments()->count());
        $this->assertTrue($service->canMutate($user->id, $hazard));
        $this->assertFalse($service->canMutate(null, $hazard));
        $this->assertTrue($service->canDelete($user->id));
        $this->assertFalse($service->canDelete(null));
        $this->assertTrue($service->canDelete($user->id, $hazard));
        $this->assertFalse($service->canDelete(User::factory()->create()->id, $hazard));
        $this->assertTrue($service->canDelete(
            User::factory()->create()->id,
            HazardReport::factory()->create(['user_id' => null])
        ));

        $result = $service->update($hazard, [
            'risk_level_code' => 'low',
            'description' => 'Peligro actualizado',
            'comments' => [
                ['author_name' => 'Vecino', 'comment_text' => 'Comentario actualizado'],
            ],
        ]);

        $this->assertFalse($result['conflict']);
        $this->assertSame('low', $result['hazard']->risk_level_code);
        $this->assertSame('Peligro actualizado', $result['hazard']->narrative_description);
        $this->assertGreaterThanOrEqual(1, $service->paginate(['risk_level' => 'low', 'per_page' => 5])->total());

        $payload = (new HazardResponseFormatter)->formatHazard($result['hazard']);
        $this->assertSame('low', $payload['risk_level_code']);

        $service->delete($hazard);
        $this->assertDatabaseMissing('hazard_reports', ['id' => $hazard->id]);
    }

    /**
     * F1-020: Hazard sync legacy path is covered and documented as current behavior.
     */
    public function test_hazard_sync_documents_removed_local_sync_contract_as_error(): void
    {
        $service = new HazardReportService(new HazardValueNormalizer, new ReportCommentService);

        $result = $service->sync([[
            'local_id' => 'hazard-local',
            'incident_latitude' => 4.71,
            'incident_longitude' => -74.07,
            'impact_radius_meters' => 100,
            'risk_level_code' => 'medium',
            'category_code' => 'pest_presence',
            'estimated_duration_code' => '1_day',
            'description' => 'Sync removed',
            'last_modified_at' => now()->toDateTimeString(),
        ]], User::factory()->create()->id);

        $this->assertSame(1, $result['errors']);
        $this->assertSame('hazard-local', $result['details'][0]['local_id']);
    }

    /**
     * F1-020-extra: unsynced returns created hazards.
     */
    public function test_unsynced_returns_created_hazards(): void
    {
        HazardReport::factory()->create();

        $unsynced = (new HazardReportService(new HazardValueNormalizer, new ReportCommentService))->unsynced();

        $this->assertGreaterThanOrEqual(1, $unsynced->count());
    }
}
