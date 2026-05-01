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
            'local_id' => 'pet-1',
            'local_uuid' => 'pet-1',
            'name' => 'Luna',
        ], $headers)->assertCreated()->json('data');

        $this->postJson('/api/lost-pet-reports', [
            'local_id' => 'lost-1',
            'pet_local_uuid' => $pet['local_uuid'],
            'last_seen_latitude' => 3.4516,
            'last_seen_longitude' => -76.5320,
            'details' => 'Brown dog with blue collar',
            'disappearance_date' => now()->format('Y-m-d H:i:s'),
            'phone' => '5551234',
        ], $headers)->assertCreated();

        $this->assertSame('perdida', Pet::query()->firstOrFail()->status);

        $this->postJson('/api/lost-pet-reports', [
            'local_id' => 'lost-2',
            'pet_local_uuid' => $pet['local_uuid'],
            'last_seen_latitude' => 3.4516,
            'last_seen_longitude' => -76.5320,
            'details' => 'Still missing',
            'disappearance_date' => now()->format('Y-m-d H:i:s'),
            'phone' => '5551234',
        ], $headers)->assertUnprocessable();
    }

    public function test_mark_pet_found_normalizes_pet_and_closes_active_lost_report(): void
    {
        $user = User::factory()->create();
        $headers = $this->authHeaders($user);

        $pet = Pet::query()->create([
            'user_id' => $user->id,
            'local_id' => 'pet-1',
            'local_uuid' => 'pet-1',
            'name' => 'Luna',
            'status' => 'perdida',
            'sync_status' => 'synced',
            'last_modified_at' => now(),
        ]);
        $pet->update(['remote_id' => (string) $pet->id]);

        LostPetReport::query()->create([
            'user_id' => $user->id,
            'pet_id' => $pet->id,
            'pet_local_uuid' => $pet->local_uuid,
            'local_id' => 'lost-1',
            'last_seen_latitude' => 3.4516,
            'last_seen_longitude' => -76.5320,
            'details' => 'Lost',
            'disappearance_date' => now(),
            'phone' => '5551234',
            'sync_status' => 'synced',
            'last_modified_at' => now(),
        ]);

        $this->postJson('/api/pets/'.$pet->id.'/mark-found', [], $headers)
            ->assertOk()
            ->assertJsonPath('data.status', 'normal');

        $this->assertSame('deleted', LostPetReport::query()->firstOrFail()->sync_status);
    }

    public function test_found_report_without_match_creates_ownerless_pet(): void
    {
        $user = User::factory()->create();
        $headers = $this->authHeaders($user);

        $this->postJson('/api/found-pet-reports', [
            'local_id' => 'found-1',
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

    public function test_found_report_without_match_preserves_client_pet_local_uuid(): void
    {
        $user = User::factory()->create();
        $headers = $this->authHeaders($user);

        $this->postJson('/api/found-pet-reports/sync', [
            'found_pet_reports' => [[
                'local_id' => 'found-local-2',
                'remote_id' => null,
                'pet_local_uuid' => 'found_pet_found-local-2',
                'matched_lost_pet_report_id' => null,
                'latitude' => 3.4520,
                'longitude' => -76.5310,
                'details' => 'Small white cat',
                'found_date' => now()->format('Y-m-d H:i:s'),
                'photo_url' => 'https://example.com/found.jpg',
                'phone' => '3001234567',
                'comments' => [],
                'sync_status' => 'created',
                'last_modified_at' => now()->format('Y-m-d H:i:s'),
            ]],
        ], $headers)->assertOk();

        $pet = Pet::query()->firstOrFail();
        $report = FoundPetReport::query()->firstOrFail();

        $this->assertSame('found_pet_found-local-2', $pet->local_uuid);
        $this->assertSame('found_pet_found-local-2', $pet->local_id);
        $this->assertSame('found_pet_found-local-2', $report->pet_local_uuid);
    }

    public function test_found_report_sync_links_to_selected_lost_pet_context(): void
    {
        $user = User::factory()->create();
        $headers = $this->authHeaders($user);

        $pet = Pet::query()->create([
            'user_id' => $user->id,
            'local_id' => 'pet-1',
            'local_uuid' => 'pet-1',
            'remote_id' => '101',
            'name' => 'Luna',
            'status' => 'perdida',
            'sync_status' => 'synced',
            'last_modified_at' => now(),
        ]);

        $lostReport = LostPetReport::query()->create([
            'user_id' => $user->id,
            'pet_id' => $pet->id,
            'pet_local_uuid' => $pet->local_uuid,
            'local_id' => 'lost-1',
            'remote_id' => '202',
            'last_seen_latitude' => 3.4516,
            'last_seen_longitude' => -76.5320,
            'details' => 'Lost near the park',
            'disappearance_date' => now(),
            'phone' => '5551234',
            'sync_status' => 'synced',
            'last_modified_at' => now(),
        ]);

        $this->postJson('/api/found-pet-reports/sync', [
            'found_pet_reports' => [[
                'local_id' => 'found-local-1',
                'remote_id' => null,
                'pet_local_uuid' => $pet->local_uuid,
                'matched_lost_pet_report_id' => 202,
                'latitude' => 3.4520,
                'longitude' => -76.5310,
                'details' => 'Seen safe with a neighbor',
                'found_date' => now()->format('Y-m-d H:i:s'),
                'photo_url' => 'https://example.com/found.jpg',
                'phone' => '3001234567',
                'comments' => [],
                'sync_status' => 'created',
                'last_modified_at' => now()->format('Y-m-d H:i:s'),
            ]],
        ], $headers)->assertOk();

        $foundReport = FoundPetReport::query()->firstOrFail();
        $this->assertSame($pet->id, $foundReport->pet_id);
        $this->assertSame($lostReport->id, $foundReport->matched_lost_pet_report_id);
        $this->assertSame($pet->local_uuid, $foundReport->pet_local_uuid);
    }

    public function test_lost_report_sync_resolves_pet_by_remote_id_when_needed(): void
    {
        $user = User::factory()->create();
        $headers = $this->authHeaders($user);

        $pet = Pet::query()->create([
            'user_id' => $user->id,
            'local_id' => 'pet-sync-1',
            'local_uuid' => 'pet-sync-1',
            'remote_id' => '7001',
            'name' => 'Milo',
            'status' => 'normal',
            'sync_status' => 'synced',
            'last_modified_at' => now(),
        ]);

        $this->postJson('/api/lost-pet-reports/sync', [
            'lost_pet_reports' => [[
                'local_id' => 'lost-sync-1',
                'remote_id' => null,
                'pet_local_uuid' => 'pet-sync-1',
                'pet_remote_id' => '7001',
                'last_seen_latitude' => 3.4516,
                'last_seen_longitude' => -76.5320,
                'details' => 'Lost near the river',
                'disappearance_date' => now()->format('Y-m-d H:i:s'),
                'photo_url' => 'https://example.com/lost.jpg',
                'phone' => '5551234',
                'comments' => [],
                'sync_status' => 'created',
                'last_modified_at' => now()->format('Y-m-d H:i:s'),
            ]],
        ], $headers)->assertOk();

        $report = LostPetReport::query()->firstOrFail();
        $this->assertSame($pet->id, $report->pet_id);
        $this->assertSame($pet->local_uuid, $report->pet_local_uuid);
    }
}
