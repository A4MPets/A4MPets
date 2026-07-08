<?php

namespace App\Models\Concerns;

trait HasPetPhotoUrl
{
    public function getPetPhotoUrlAttribute(): ?string
    {
        $pet = $this->relationLoaded('pet') ? $this->pet : $this->pet()->first();

        return $this->photo_url ?? $pet?->photo_path;
    }
}
