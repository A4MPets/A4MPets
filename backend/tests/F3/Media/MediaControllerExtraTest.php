<?php

namespace Tests\F3\Media;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

/**
 * F3-021/F3-022-extra: Additional media controller coverage.
 */
class MediaControllerExtraTest extends TestCase
{
    use RefreshDatabase;

    public function test_show_returns_existing_media_and_404_for_missing_or_invalid_file(): void
    {
        Storage::fake('local');
        Storage::disk('local')->put('media/pets/sample.png', 'png-bytes');

        $this->get('/api/media/pets/sample.png')
            ->assertStatus(200);

        $this->get('/api/media/pets/missing.png')
            ->assertStatus(404);

        $this->get('/api/media/pets/../bad.png')
            ->assertStatus(404);
    }

    public function test_upload_detects_extension_from_filename_and_data_uri_mime(): void
    {
        Storage::fake('local');
        $raw = base64_encode('fake-image-binary');

        $response = $this->postJson('/api/media/upload', [
            'bucket' => 'profiles',
            'image_data' => $raw,
            'file_name' => 'avatar.jpeg',
        ]);
        $response->assertStatus(200)
            ->assertJsonPath('data.bucket', 'profiles')
            ->assertJsonPath('success', true);
        $this->assertStringEndsWith('.jpg', $response->json('data.file_name'));

        $response = $this->postJson('/api/media/upload', [
            'bucket' => 'generic_reports',
            'image_data' => 'data:image/webp;base64,'.$raw,
        ]);
        $response->assertStatus(200)
            ->assertJsonPath('success', true);
        $this->assertStringEndsWith('.webp', $response->json('data.file_name'));
    }
}
