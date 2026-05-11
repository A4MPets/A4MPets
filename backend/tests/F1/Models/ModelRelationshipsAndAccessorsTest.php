<?php

namespace Tests\F1\Models;

use App\Models\ApiToken;
use App\Models\FoundPetReport;
use App\Models\GenericReport;
use App\Models\HazardCategory;
use App\Models\HazardComment;
use App\Models\HazardEstimatedDuration;
use App\Models\HazardReport;
use App\Models\HazardRiskLevel;
use App\Models\LostPetReport;
use App\Models\Pet;
use App\Models\ReportComment;
use App\Models\RoutePoint;
use App\Models\TravelRoute;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\MorphMany;
use Illuminate\Database\Eloquent\Relations\MorphTo;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * F1-006/F1-010: Model relationship, accessor, scope, and hash coverage.
 */
class ModelRelationshipsAndAccessorsTest extends TestCase
{
    use RefreshDatabase;

    /**
     * F1-006: User, Pet, ApiToken and TravelRoute relationships are defined.
     */
    public function test_user_and_pet_relationships_are_defined(): void
    {
        $user = User::factory()->create();
        $pet = Pet::factory()->create(['user_id' => $user->id]);
        $route = TravelRoute::create([
            'user_id' => $user->id,
            'name' => 'Ruta modelo',
            'points_json' => json_encode([['lat' => 4.71, 'lng' => -74.07]]),
        ]);
        $token = ApiToken::create([
            'user_id' => $user->id,
            'name' => 'model-test',
            'token_hash' => hash('sha256', 'plain'),
        ]);

        $this->assertInstanceOf(HasMany::class, $user->apiTokens());
        $this->assertInstanceOf(HasMany::class, $user->pets());
        $this->assertInstanceOf(HasMany::class, $user->routes());
        $this->assertInstanceOf(BelongsTo::class, $token->user());
        $this->assertInstanceOf(BelongsTo::class, $pet->user());
        $this->assertInstanceOf(HasMany::class, $pet->lostPetReports());
        $this->assertInstanceOf(HasMany::class, $pet->foundPetReports());
        $this->assertSame($route->id, $user->routes()->first()->id);
    }

    /**
     * F1-007: Report accessors return comments_json, reported_by_username and pet photo fallbacks.
     */
    public function test_report_accessors_return_comments_json_and_pet_photo_fallbacks(): void
    {
        $user = User::factory()->create(['name' => 'QA Reporter']);
        $pet = Pet::factory()->create(['user_id' => $user->id, 'photo_path' => 'pets/luna.png']);
        $lost = LostPetReport::create([
            'user_id' => $user->id,
            'pet_id' => $pet->id,
            'last_seen_latitude' => 4.71,
            'last_seen_longitude' => -74.07,
            'details' => 'Lost details',
            'disappearance_date' => now(),
            'phone' => '300',
        ]);
        $found = FoundPetReport::create([
            'user_id' => $user->id,
            'pet_id' => $pet->id,
            'matched_lost_pet_report_id' => $lost->id,
            'latitude' => 4.72,
            'longitude' => -74.08,
            'details' => 'Found details',
            'found_date' => now(),
        ]);
        $generic = GenericReport::create([
            'user_id' => $user->id,
            'latitude' => 4.73,
            'longitude' => -74.09,
            'description' => 'Generic details',
            'reported_date' => now(),
            'risk_level_code' => 'medium',
            'impact_radius_meters' => 25,
        ]);

        foreach ([$lost, $found, $generic] as $report) {
            ReportComment::create([
                'commentable_type' => $report->getMorphClass(),
                'commentable_id' => $report->getKey(),
                'user_id' => $user->id,
                'author_name' => 'QA Reporter',
                'is_anonymous' => false,
                'comment_text' => 'Visible comment',
                'commented_at' => Carbon::parse('2026-05-08 12:00:00'),
                'content_hash' => ReportComment::makeContentHash([
                    'commentable_type' => $report->getMorphClass(),
                    'commentable_id' => $report->getKey(),
                    'user_id' => $user->id,
                    'author_name' => 'QA Reporter',
                    'is_anonymous' => false,
                    'comment_text' => 'Visible comment',
                    'commented_at' => Carbon::parse('2026-05-08 12:00:00'),
                ]),
            ]);
        }

        $this->assertInstanceOf(BelongsTo::class, $lost->user());
        $this->assertInstanceOf(BelongsTo::class, $lost->pet());
        $this->assertInstanceOf(MorphMany::class, $lost->comments());
        $this->assertSame('pets/luna.png', $lost->pet_photo_url);
        $this->assertStringContainsString('Visible comment', $lost->comments_json);

        $this->assertInstanceOf(BelongsTo::class, $found->matchedLostPetReport());
        $this->assertSame('pets/luna.png', $found->pet_photo_url);
        $this->assertStringContainsString('Visible comment', $found->comments_json);

        $this->assertInstanceOf(BelongsTo::class, $generic->user());
        $this->assertSame('QA Reporter', $generic->reported_by_username);
        $this->assertStringContainsString('Visible comment', $generic->comments_json);
    }

    /**
     * F1-008: HazardReport lookup accessors, scopes and status helpers work as unit behavior.
     */
    public function test_hazard_model_lookup_accessors_scopes_and_status_helpers(): void
    {
        $user = User::factory()->create();
        $hazard = HazardReport::create([
            'user_id' => $user->id,
            'incident_latitude' => 4.71,
            'incident_longitude' => -74.07,
            'impact_radius_meters' => 100,
            'risk_level_code' => 'unknown',
            'category_code' => 'aggressive_animals',
            'estimated_duration_code' => '1_week',
            'description' => 'Hazard details',
            'reported_by_username' => 'qa',
            'status' => 'created',
        ]);

        $this->assertSame('undefined', $hazard->risk_level_code);
        $this->assertSame('possible_rabies_vectors', $hazard->category_code);
        $this->assertSame('1_week', $hazard->estimated_duration_code);
        $this->assertTrue($hazard->isLocal());
        $this->assertFalse($hazard->isSynced());
        $this->assertGreaterThanOrEqual(1, HazardReport::nearby(4.71, -74.07, 5)->count());
        $this->assertGreaterThanOrEqual(1, HazardReport::byRiskLevel('undefined')->count());
        $this->assertGreaterThanOrEqual(1, HazardReport::unsynced()->count());

        $hazard->status = 'synced';
        $hazard->setAttribute('remote_id', 'remote-1');
        $this->assertTrue($hazard->isSynced());
        HazardReport::factory()->create(['status' => 'synced']);
        $this->assertGreaterThanOrEqual(1, HazardReport::synced()->count());

        $older = HazardReport::factory()->create(['reported_at' => now()]);
        $older->setAttribute('last_modified_at', now()->subMinute());
        $hazard->setAttribute('last_modified_at', now());
        $this->assertTrue($hazard->resolvesConflictWith($older));

        $this->assertNotNull(HazardRiskLevel::idByCode('high'));
        $this->assertNotNull(HazardCategory::idByCode('pest_presence'));
        $this->assertNotNull(HazardEstimatedDuration::idByCode('1_day'));
    }

    /**
     * F1-009: ReportComment and HazardComment hashes and relationships are stable.
     */
    public function test_comment_hashes_and_relationships_are_stable_to_second_precision(): void
    {
        $user = User::factory()->create();
        $hazard = HazardReport::factory()->create(['user_id' => $user->id]);
        $timestamp = Carbon::parse('2026-05-08 10:11:12.987');

        $reportHashA = ReportComment::makeContentHash([
            'commentable_type' => HazardReport::class,
            'commentable_id' => $hazard->id,
            'user_id' => $user->id,
            'author_name' => 'QA',
            'is_anonymous' => false,
            'comment_text' => 'Same second',
            'commented_at' => $timestamp,
        ]);
        $reportHashB = ReportComment::makeContentHash([
            'commentable_type' => HazardReport::class,
            'commentable_id' => $hazard->id,
            'user_id' => $user->id,
            'author_name' => 'QA',
            'is_anonymous' => false,
            'comment_text' => 'Same second',
            'commented_at' => $timestamp->getTimestampMs(),
        ]);

        $comment = ReportComment::create([
            'commentable_type' => HazardReport::class,
            'commentable_id' => $hazard->id,
            'user_id' => $user->id,
            'author_name' => 'QA',
            'is_anonymous' => false,
            'comment_text' => 'Same second',
            'commented_at' => $timestamp,
            'content_hash' => $reportHashA,
        ]);

        $this->assertSame($reportHashA, $reportHashB);
        $this->assertInstanceOf(MorphTo::class, $comment->commentable());
        $this->assertInstanceOf(BelongsTo::class, $comment->user());

        $hazardHash = HazardComment::makeContentHash([
            'hazard_report_id' => $hazard->id,
            'author_name' => 'QA',
            'is_anonymous' => true,
            'comment_text' => 'Hazard legacy',
            'commented_at' => '2026-05-08 10:11:12',
        ]);
        $hazardComment = HazardComment::create([
            'hazard_report_id' => $hazard->id,
            'author_name' => 'QA',
            'is_anonymous' => true,
            'comment_text' => 'Hazard legacy',
            'commented_at' => '2026-05-08 10:11:12',
            'content_hash' => $hazardHash,
        ]);

        $this->assertSame(64, strlen($hazardHash));
        $this->assertInstanceOf(BelongsTo::class, $hazardComment->hazardReport());
        $this->assertInstanceOf(BelongsTo::class, $hazardComment->user());
    }

    /**
     * F1-010: TravelRoute points_json decodes, normalizes and syncs RoutePoint rows.
     */
    public function test_travel_route_points_json_decodes_and_syncs_route_points(): void
    {
        $user = User::factory()->create();
        $route = TravelRoute::create([
            'user_id' => $user->id,
            'name' => 'Ruta accesores',
            'points_json' => json_encode([
                ['latitude' => 4.71, 'longitude' => -74.07],
                ['lat' => '4.72', 'lng' => '-74.08'],
                ['lat' => 'bad', 'lng' => -74.09],
            ]),
        ]);

        $this->assertInstanceOf(BelongsTo::class, $route->user());
        $this->assertInstanceOf(HasMany::class, $route->routePoints());
        $this->assertSame(
            '[{"lat":4.71,"lng":-74.07},{"lat":4.72,"lng":-74.08}]',
            $route->refresh()->points_json
        );

        $point = $route->routePoints()->first();
        $this->assertInstanceOf(RoutePoint::class, $point);
        $this->assertInstanceOf(BelongsTo::class, $point->route());
    }
}
