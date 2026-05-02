<?php

namespace App\Http\Requests\Hazards;

use Illuminate\Foundation\Http\FormRequest;

class StoreHazardRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'incident_latitude' => ['required', 'numeric', 'between:-90,90'],
            'incident_longitude' => ['required', 'numeric', 'between:-180,180'],
            'impact_radius_meters' => ['required', 'numeric', 'min:10', 'max:10000'],
            'risk_level_code' => ['required', 'string', 'max:32'],
            'category_code' => ['nullable', 'string', 'max:64'],
            'estimated_duration_code' => ['nullable', 'string', 'max:64'],
            'description' => ['nullable', 'string', 'max:500'],
            'narrative_description' => ['nullable', 'string', 'max:500'],
            'reported_at' => ['nullable', 'date'],
            'evidence_photo_url' => ['nullable', 'string', 'max:500'],
            'reported_by_username' => ['nullable', 'string', 'max:100'],
        ];
    }
}
