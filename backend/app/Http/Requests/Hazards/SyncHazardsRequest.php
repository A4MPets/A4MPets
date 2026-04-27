<?php

namespace App\Http\Requests\Hazards;

use Illuminate\Foundation\Http\FormRequest;

class SyncHazardsRequest extends FormRequest
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
            'hazards' => ['required', 'array'],
            'hazards.*.local_id' => ['required', 'string'],
            'hazards.*.remote_id' => ['nullable', 'string'],
            'hazards.*.incident_latitude' => ['required', 'numeric', 'between:-90,90'],
            'hazards.*.incident_longitude' => ['required', 'numeric', 'between:-180,180'],
            'hazards.*.impact_radius_meters' => ['required', 'numeric', 'min:10', 'max:10000'],
            'hazards.*.risk_level_code' => ['required', 'string', 'max:32'],
            'hazards.*.category_code' => ['nullable', 'string', 'max:64'],
            'hazards.*.estimated_duration_code' => ['nullable', 'string', 'max:64'],
            'hazards.*.description' => ['nullable', 'string', 'max:500'],
            'hazards.*.narrative_description' => ['nullable', 'string', 'max:500'],
            'hazards.*.reported_at' => ['nullable', 'date'],
            'hazards.*.evidence_photo_url' => ['nullable', 'string', 'max:500'],
            'hazards.*.reported_by_username' => ['nullable', 'string', 'max:100'],
            'hazards.*.status' => ['nullable', 'string', 'max:32'],
            'hazards.*.last_modified_at' => ['required', 'date_format:Y-m-d H:i:s'],
            'hazards.*.comments' => ['sometimes', 'array'],
        ];
    }
}
