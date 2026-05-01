<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\CreatesApiToken;
use Tests\TestCase;

class ReportCommentsApiTest extends TestCase
{
    use CreatesApiToken;
    use RefreshDatabase;

    public function test_lost_and_found_report_comment_endpoints_work(): void
    {
        $user = User::factory()->create();
        $headers = $this->authHeaders($user);
        $pet = $this->postJson('/api/pets', [
            'local_id' => 'pet-comment-1',
            'local_uuid' => 'pet-comment-1',
            'name' => 'Milo',
            'photo_path' => 'https://example.com/lost.jpg',
        ], $headers)->assertCreated()->json('data');

        $lostReportId = $this->postJson('/api/lost-pet-reports', [
            'local_id' => 'lost-comment-1',
            'pet_local_uuid' => $pet['local_uuid'],
            'last_seen_latitude' => 3.4516,
            'last_seen_longitude' => -76.5320,
            'details' => 'Brown dog with blue collar',
            'disappearance_date' => now()->subDay()->toIso8601String(),
            'photo_url' => 'https://example.com/lost.jpg',
            'phone' => '5551234',
        ], $headers)->json('data.id');

        $this->postJson('/api/lost-pet-reports/'.$lostReportId.'/comments', [
            'comment_text' => 'I saw this pet near the park.',
        ], $headers)
            ->assertCreated()
            ->assertJsonPath('data.comment_text', 'I saw this pet near the park.');

        $this->getJson('/api/lost-pet-reports/'.$lostReportId.'/comments', $headers)
            ->assertOk()
            ->assertJsonPath('data.0.comment_text', 'I saw this pet near the park.');

        $foundReportId = $this->postJson('/api/found-pet-reports', [
            'local_id' => 'found-comment-1',
            'latitude' => 3.4520,
            'longitude' => -76.5330,
            'details' => 'Small white dog waiting by the corner',
            'found_date' => now()->subHours(2)->toIso8601String(),
            'photo_url' => 'https://example.com/found.jpg',
            'phone' => '5559876',
        ], $headers)->json('data.id');

        $this->postJson('/api/found-pet-reports/'.$foundReportId.'/comments', [
            'comment_text' => 'This looks like the same pet from another alert.',
        ], $headers)
            ->assertCreated()
            ->assertJsonPath(
                'data.comment_text',
                'This looks like the same pet from another alert.'
            );

        $this->getJson('/api/found-pet-reports/'.$foundReportId.'/comments', $headers)
            ->assertOk()
            ->assertJsonPath(
                'data.0.comment_text',
                'This looks like the same pet from another alert.'
            );
    }
}
