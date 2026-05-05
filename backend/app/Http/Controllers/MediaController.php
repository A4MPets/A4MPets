<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class MediaController extends Controller
{
    public function upload(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'bucket' => ['required', 'string', 'in:pets,hazards,profiles,lost_pets,found_pets,generic_reports'],
            'image_data' => ['required', 'string'],
            'file_name' => ['nullable', 'string', 'max:140'],
        ]);

        $binary = $this->decodeImagePayload($validated['image_data']);
        if ($binary === null) {
            return response()->json([
                'success' => false,
                'message' => 'Formato de imagen no valido.',
            ], 422);
        }
        $binary = $this->normalizeImageOrientation($binary);

        $bucket = $validated['bucket'];
        $extension = $this->detectExtension(
            $validated['image_data'],
            $validated['file_name'] ?? null,
        );
        $hash = sha1($binary);
        $fileName = $hash.'.'.$extension;
        $relativePath = 'media/'.$bucket.'/'.$fileName;

        if (! Storage::disk('local')->exists($relativePath)) {
            Storage::disk('local')->put($relativePath, $binary);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'url' => url('/api/media/'.$bucket.'/'.$fileName),
                'bucket' => $bucket,
                'file_name' => $fileName,
            ],
        ]);
    }

    public function show(string $bucket, string $fileName)
    {
        if (! in_array($bucket, ['pets', 'hazards', 'profiles', 'lost_pets', 'found_pets', 'generic_reports'], true)) {
            abort(404);
        }

        if (! preg_match('/^[a-zA-Z0-9._-]+$/', $fileName)) {
            abort(404);
        }

        $relativePath = 'media/'.$bucket.'/'.$fileName;
        if (! Storage::disk('local')->exists($relativePath)) {
            abort(404);
        }

        $absolutePath = Storage::disk('local')->path($relativePath);
        $mimeType = Storage::disk('local')->mimeType($relativePath) ?? 'application/octet-stream';

        return response()->file($absolutePath, [
            'Content-Type' => $mimeType,
            'Cache-Control' => 'public, max-age=31536000, immutable',
        ]);
    }

    private function decodeImagePayload(string $payload): ?string
    {
        $raw = $payload;
        if (str_starts_with($payload, 'data:')) {
            $parts = explode(',', $payload, 2);
            if (count($parts) !== 2) {
                return null;
            }
            $raw = $parts[1];
        }

        $decoded = base64_decode($raw, true);
        if ($decoded === false || $decoded === '') {
            return null;
        }

        return $decoded;
    }

    private function detectExtension(string $payload, ?string $fileName): string
    {
        $mime = null;
        if (preg_match('/^data:(image\/[a-zA-Z0-9.+-]+);base64,/', $payload, $matches) === 1) {
            $mime = strtolower($matches[1]);
        }

        if ($mime !== null) {
            return match ($mime) {
                'image/jpeg', 'image/jpg' => 'jpg',
                'image/gif' => 'gif',
                'image/webp' => 'webp',
                'image/bmp' => 'bmp',
                default => 'png',
            };
        }

        if (is_string($fileName) && $fileName !== '') {
            $ext = strtolower(pathinfo($fileName, PATHINFO_EXTENSION));
            if (in_array($ext, ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp'], true)) {
                return $ext === 'jpeg' ? 'jpg' : $ext;
            }
        }

        return 'png';
    }

    private function normalizeImageOrientation(string $binary): string
    {
        if (! function_exists('exif_read_data') || ! function_exists('imagecreatefromstring')) {
            return $binary;
        }

        $info = @getimagesizefromstring($binary);
        if (! is_array($info) || ($info['mime'] ?? null) !== 'image/jpeg') {
            return $binary;
        }

        $tempPath = tempnam(sys_get_temp_dir(), 'a4m_img_');
        if ($tempPath === false) {
            return $binary;
        }

        try {
            file_put_contents($tempPath, $binary);
            $exif = @exif_read_data($tempPath);
            $orientation = is_array($exif) ? (int) ($exif['Orientation'] ?? 1) : 1;

            if (! in_array($orientation, [3, 6, 8], true)) {
                return $binary;
            }

            $image = @imagecreatefromstring($binary);
            if ($image === false) {
                return $binary;
            }

            $rotated = match ($orientation) {
                3 => imagerotate($image, 180, 0),
                6 => imagerotate($image, -90, 0),
                8 => imagerotate($image, 90, 0),
                default => $image,
            };

            if ($rotated === false) {
                imagedestroy($image);

                return $binary;
            }

            ob_start();
            imagejpeg($rotated, null, 92);
            $normalized = ob_get_clean();

            imagedestroy($image);
            if ($rotated !== $image) {
                imagedestroy($rotated);
            }

            return is_string($normalized) && $normalized !== '' ? $normalized : $binary;
        } finally {
            @unlink($tempPath);
        }
    }
}
