<?php

namespace Tests\Feature;

use App\Models\FoundPetReport;
use App\Models\LostPetReport;
use App\Models\Pet;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\CreatesApiToken;
use Tests\TestCase;

class PetUsageApiTest extends TestCase
{
    use CreatesApiToken;
    use RefreshDatabase;

    public function test_lost_report_marks_pet_lost_and_blocks_duplicate_active_report(): void
    {
        $user = User::factory()->create();
        $headers = $this->authHeaders($user);

        $pet = $this->postJson('/api/pets', [
            'name' => 'Luna',
        ], $headers)->assertCreated()->json('data');

        $this->postJson('/api/lost-pet-reports', [
            'pet_id' => $pet['id'],
            'last_seen_latitude' => 3.4516,
            'last_seen_longitude' => -76.5320,
            'details' => 'Brown dog with blue collar',
            'disappearance_date' => now()->format('Y-m-d H:i:s'),
            'phone' => '5551234',
        ], $headers)->assertCreated();

        $this->assertSame('perdida', Pet::query()->firstOrFail()->status);

        $this->postJson('/api/lost-pet-reports', [
            'pet_id' => $pet['id'],
            'last_seen_latitude' => 3.4516,
            'last_seen_longitude' => -76.5320,
            'details' => 'Still missing',
            'disappearance_date' => now()->format('Y-m-d H:i:s'),
            'phone' => '5551234',
        ], $headers)->assertUnprocessable();
    }

    public function test_mark_pet_found_normalizes_pet_and_deletes_active_lost_report(): void
    {
        $user = User::factory()->create();
        $headers = $this->authHeaders($user);

        $pet = Pet::query()->create([
            'user_id' => $user->id,
            'name' => 'Luna',
            'status' => 'perdida',
        ]);

        LostPetReport::query()->create([
            'user_id' => $user->id,
            'pet_id' => $pet->id,
            'last_seen_latitude' => 3.4516,
            'last_seen_longitude' => -76.5320,
            'details' => 'Lost',
            'disappearance_date' => now(),
            'phone' => '5551234',
        ]);

        $this->postJson('/api/pets/'.$pet->id.'/mark-found', [], $headers)
            ->assertOk()
            ->assertJsonPath('data.status', 'normal');

        $this->assertDatabaseMissing('lost_pet_reports', ['pet_id' => $pet->id]);
    }

    public function test_found_report_without_match_creates_ownerless_pet(): void
    {
        $user = User::factory()->create();
        $headers = $this->authHeaders($user);

        $this->postJson('/api/found-pet-reports', [
            'latitude' => 3.4516,
            'longitude' => -76.5320,
            'details' => 'Small white cat',
            'found_date' => now()->format('Y-m-d H:i:s'),
            'photo_url' => 'https://example.com/found.jpg',
        ], $headers)->assertCreated();

        $pet = Pet::query()->firstOrFail();
        $this->assertTrue($pet->is_ownerless);
        $this->assertNull($pet->name);
        $this->assertSame($pet->id, FoundPetReport::query()->firstOrFail()->pet_id);
    }

    public function test_found_report_links_to_selected_lost_pet_context(): void
    {
        $user = User::factory()->create();
        $headers = $this->authHeaders($user);

        $pet = Pet::query()->create([
            'user_id' => $user->id,
            'name' => 'Luna',
            'status' => 'perdida',
        ]);

        $lostReport = LostPetReport::query()->create([
            'user_id' => $user->id,
            'pet_id' => $pet->id,
            'last_seen_latitude' => 3.4516,
            'last_seen_longitude' => -76.5320,
            'details' => 'Lost near the park',
            'disappearance_date' => now(),
            'phone' => '5551234',
        ]);

        $this->postJson('/api/found-pet-reports', [
            'matched_lost_pet_report_id' => $lostReport->id,
            'latitude' => 3.4520,
            'longitude' => -76.5310,
            'details' => 'Seen safe with a neighbor',
            'found_date' => now()->format('Y-m-d H:i:s'),
            'photo_url' => 'https://example.com/found.jpg',
            'phone' => '3001234567',
        ], $headers)->assertCreated();

        $foundReport = FoundPetReport::query()->firstOrFail();
        $this->assertSame($pet->id, $foundReport->pet_id);
        $this->assertSame($lostReport->id, $foundReport->matched_lost_pet_report_id);
    }

    public function test_found_report_can_link_to_public_lost_report_from_another_user(): void
    {
        $lostOwner = User::factory()->create();
        $finder = User::factory()->create();
        $headers = $this->authHeaders($finder);

        $pet = Pet::query()->create([
            'user_id' => $lostOwner->id,
            'name' => 'Nala',
            'photo_path' => 'https://example.com/nala.jpg',
            'status' => 'perdida',
        ]);

        $lostReport = LostPetReport::query()->create([
            'user_id' => $lostOwner->id,
            'pet_id' => $pet->id,
            'last_seen_latitude' => 3.4516,
            'last_seen_longitude' => -76.5320,
            'details' => 'Lost near the park',
            'disappearance_date' => now(),
            'phone' => '5551234',
        ]);

        $this->postJson('/api/found-pet-reports', [
            'matched_lost_pet_report_id' => $lostReport->id,
            'latitude' => 3.4520,
            'longitude' => -76.5310,
            'details' => 'Seen safe with a neighbor',
            'found_date' => now()->format('Y-m-d H:i:s'),
            'photo_url' => 'https://example.com/found-nala.jpg',
            'phone' => '3001234567',
        ], $headers)->assertCreated();

        $foundReport = FoundPetReport::query()->firstOrFail();
        $this->assertSame($pet->id, $foundReport->pet_id);
        $this->assertSame($lostReport->id, $foundReport->matched_lost_pet_report_id);
        $this->assertSame('Nala', $foundReport->pet->name);
    }
}
