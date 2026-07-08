<?php

namespace Tests\F3\Auth;

use App\Models\FoundPetReport;
use App\Models\GenericReport;
use App\Models\HazardComment;
use App\Models\HazardReport;
use App\Models\LostPetReport;
use App\Models\Pet;
use App\Models\ReportComment;
use App\Models\TravelRoute;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Tests\Concerns\CreatesApiToken;
use Tests\TestCase;

class AccountDeletionTest extends TestCase
{
    use CreatesApiToken, RefreshDatabase;

    public function test_delete_account_rejects_invalid_confirmation_or_password(): void
    {
        $user = User::factory()->create([
            'password' => Hash::make('delete-pass-123'),
        ]);

        $this->withHeaders($this->authHeaders($user))
            ->deleteJson('/api/auth/account', [
                'password' => 'delete-pass-123',
                'confirmation' => 'BORRAR',
            ])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['confirmation']);

        $this->withHeaders($this->authHeaders($user))
            ->deleteJson('/api/auth/account', [
                'password' => 'wrong-pass',
                'confirmation' => 'ELIMINAR',
            ])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['password']);

        $this->assertDatabaseHas('users', ['id' => $user->id]);
    }

    public function test_delete_account_removes_private_data_and_anonymizes_community_records(): void
    {
        Storage::fake('local');

        $user = User::factory()->create([
            'password' => Hash::make('delete-pass-123'),
            'profile_photo_url' => url('/api/media/profiles/profile.png'),
        ]);
        $headers = $this->authHeaders($user);

        Storage::disk('local')->put('media/profiles/profile.png', 'profile');
        Storage::disk('local')->put('media/pets/pet.png', 'pet');
        Storage::disk('local')->put('media/hazards/hazard.png', 'hazard');
        Storage::disk('local')->put('media/lost_pets/lost.png', 'lost');
        Storage::disk('local')->put('media/found_pets/found.png', 'found');
        Storage::disk('local')->put('media/generic_reports/generic.png', 'generic');

        $pet = Pet::factory()->create([
            'user_id' => $user->id,
            'photo_path' => url('/api/media/pets/pet.png'),
        ]);
        $route = TravelRoute::create([
            'user_id' => $user->id,
            'name' => 'Ruta privada',
            'points_json' => json_encode([['lat' => 4.71, 'lng' => -74.07]]),
        ]);
        $hazard = HazardReport::factory()->create([
            'user_id' => $user->id,
            'reported_by_username' => $user->name,
            'evidence_photo_url' => url('/api/media/hazards/hazard.png'),
        ]);
        $lost = LostPetReport::factory()->create([
            'user_id' => $user->id,
            'pet_id' => $pet->id,
            'name' => 'Toby',
            'photo_url' => url('/api/media/lost_pets/lost.png'),
            'phone' => '3001234567',
        ]);
        $found = FoundPetReport::create([
            'user_id' => $user->id,
            'pet_id' => $pet->id,
            'latitude' => 4.72,
            'longitude' => -74.08,
            'details' => 'Encontrado cerca al parque',
            'found_date' => now(),
            'photo_url' => url('/api/media/found_pets/found.png'),
            'phone' => '3007654321',
        ]);
        $generic = GenericReport::create([
            'user_id' => $user->id,
            'latitude' => 4.73,
            'longitude' => -74.09,
            'description' => 'Obstaculo en via',
            'reported_date' => now(),
            'risk_level_code' => 'medium',
            'impact_radius_meters' => 80,
            'photo_url' => url('/api/media/generic_reports/generic.png'),
        ]);
        $comment = ReportComment::create([
            'commentable_type' => HazardReport::class,
            'commentable_id' => $hazard->id,
            'user_id' => $user->id,
            'author_name' => $user->name,
            'author_avatar_url' => $user->profile_photo_url,
            'is_anonymous' => false,
            'comment_text' => 'Comentario publico',
            'commented_at' => now(),
            'content_hash' => 'old-hash',
        ]);
        $legacyComment = HazardComment::create([
            'hazard_report_id' => $hazard->id,
            'user_id' => $user->id,
            'author_name' => $user->name,
            'author_avatar_url' => $user->profile_photo_url,
            'is_anonymous' => false,
            'comment_text' => 'Comentario legacy',
            'commented_at' => now(),
            'content_hash' => 'old-legacy-hash',
        ]);

        $this->assertDatabaseHas('api_tokens', ['user_id' => $user->id]);

        $this->withHeaders($headers)
            ->deleteJson('/api/auth/account', [
                'password' => 'delete-pass-123',
                'confirmation' => 'ELIMINAR',
            ])
            ->assertStatus(200)
            ->assertJsonPath('success', true);

        $this->assertDatabaseMissing('users', ['id' => $user->id]);
        $this->assertDatabaseMissing('api_tokens', ['user_id' => $user->id]);
        $this->assertDatabaseMissing('pets', ['id' => $pet->id]);
        $this->assertDatabaseMissing('routes', ['id' => $route->id]);

        $this->assertDatabaseHas('hazard_reports', [
            'id' => $hazard->id,
            'user_id' => null,
            'reported_by_username' => 'Usuario eliminado',
            'evidence_photo_url' => null,
        ]);
        $this->assertDatabaseHas('lost_pet_reports', [
            'id' => $lost->id,
            'user_id' => null,
            'pet_id' => null,
            'photo_url' => null,
            'phone' => null,
        ]);
        $this->assertDatabaseHas('found_pet_reports', [
            'id' => $found->id,
            'user_id' => null,
            'pet_id' => null,
            'photo_url' => null,
            'phone' => null,
        ]);
        $this->assertDatabaseHas('generic_reports', [
            'id' => $generic->id,
            'user_id' => null,
            'photo_url' => null,
        ]);
        $this->assertDatabaseHas('report_comments', [
            'id' => $comment->id,
            'user_id' => null,
            'author_name' => 'Usuario eliminado',
            'author_avatar_url' => null,
            'is_anonymous' => true,
            'comment_text' => 'Comentario publico',
        ]);
        $this->assertNotSame('old-hash', ReportComment::findOrFail($comment->id)->content_hash);
        $this->assertDatabaseHas('hazard_comments', [
            'id' => $legacyComment->id,
            'user_id' => null,
            'author_name' => 'Usuario eliminado',
            'author_avatar_url' => null,
            'is_anonymous' => true,
            'comment_text' => 'Comentario legacy',
        ]);
        $this->assertNotSame('old-legacy-hash', HazardComment::findOrFail($legacyComment->id)->content_hash);

        Storage::disk('local')->assertMissing('media/profiles/profile.png');
        Storage::disk('local')->assertMissing('media/pets/pet.png');
        Storage::disk('local')->assertMissing('media/hazards/hazard.png');
        Storage::disk('local')->assertMissing('media/lost_pets/lost.png');
        Storage::disk('local')->assertMissing('media/found_pets/found.png');
        Storage::disk('local')->assertMissing('media/generic_reports/generic.png');
    }
}
