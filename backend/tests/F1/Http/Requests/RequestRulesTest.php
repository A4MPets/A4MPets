<?php

namespace Tests\F1\Http\Requests;

use App\Http\Requests\Auth\LoginRequest;
use App\Http\Requests\Auth\RegisterRequest;
use App\Http\Requests\Auth\UpdateProfileRequest;
use App\Http\Requests\Hazards\StoreHazardCommentRequest;
use App\Http\Requests\Hazards\StoreHazardRequest;
use App\Http\Requests\Hazards\UpdateHazardRequest;
use App\Http\Requests\Pets\StorePetRequest;
use App\Http\Requests\Pets\UpdatePetRequest;
use App\Http\Requests\Reports\StoreFoundPetReportRequest;
use App\Http\Requests\Reports\StoreGenericReportRequest;
use App\Http\Requests\Reports\StoreLostPetReportRequest;
use App\Http\Requests\Reports\StoreReportCommentRequest;
use App\Http\Requests\Reports\UpdateFoundPetReportRequest;
use App\Http\Requests\Reports\UpdateGenericReportRequest;
use App\Http\Requests\Reports\UpdateLostPetReportRequest;
use App\Http\Requests\Routes\StoreTravelRouteRequest;
use App\Http\Requests\Routes\UpdateTravelRouteRequest;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

/**
 * F1-004/F1-005: Direct white-box coverage for FormRequest authorization and rules.
 */
class RequestRulesTest extends TestCase
{
    /**
     * @return array<string, array{0: class-string, 1: array<int, string>}>
     */
    public static function requestRulesProvider(): array
    {
        return [
            'auth login' => [LoginRequest::class, ['login', 'password']],
            'auth register' => [RegisterRequest::class, ['name', 'email', 'password']],
            'auth profile' => [UpdateProfileRequest::class, ['name', 'profile_photo_url']],
            'hazard store' => [StoreHazardRequest::class, ['incident_latitude', 'incident_longitude', 'risk_level_code']],
            'hazard update' => [UpdateHazardRequest::class, ['incident_latitude', 'incident_longitude', 'risk_level_code']],
            'hazard comment' => [StoreHazardCommentRequest::class, ['comment_text', 'author_name', 'is_anonymous']],
            'pet store' => [StorePetRequest::class, ['name', 'status', 'is_ownerless']],
            'pet update' => [UpdatePetRequest::class, ['name', 'status', 'is_ownerless']],
            'lost report store' => [StoreLostPetReportRequest::class, ['pet_id', 'details', 'phone']],
            'lost report update' => [UpdateLostPetReportRequest::class, ['pet_id', 'details', 'phone']],
            'found report store' => [StoreFoundPetReportRequest::class, ['latitude', 'longitude', 'found_date']],
            'found report update' => [UpdateFoundPetReportRequest::class, ['latitude', 'longitude', 'found_date']],
            'generic report store' => [StoreGenericReportRequest::class, ['latitude', 'longitude', 'risk_level_code']],
            'generic report update' => [UpdateGenericReportRequest::class, ['latitude', 'longitude', 'risk_level_code']],
            'report comment' => [StoreReportCommentRequest::class, ['comment_text', 'author_name', 'is_anonymous']],
            'route store' => [StoreTravelRouteRequest::class, ['name', 'points_json']],
            'route update' => [UpdateTravelRouteRequest::class, ['name', 'points_json']],
        ];
    }

    /**
     * F1-004/F1-005: Each data set validates authorize() and rules() for Auth and domain FormRequests.
     */
    #[DataProvider('requestRulesProvider')]
    public function test_requests_authorize_and_expose_expected_rules(string $requestClass, array $expectedKeys): void
    {
        $request = new $requestClass();

        $this->assertTrue($request->authorize());

        $rules = $request->rules();
        foreach ($expectedKeys as $key) {
            $this->assertArrayHasKey($key, $rules);
            $this->assertNotEmpty($rules[$key]);
        }
    }
}
