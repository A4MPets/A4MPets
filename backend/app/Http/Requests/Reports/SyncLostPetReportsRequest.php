<?php

namespace App\Http\Requests\Reports;

use Illuminate\Foundation\Http\FormRequest;

class SyncLostPetReportsRequest extends FormRequest
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
            'lost_pet_reports' => ['required', 'array'],
            'lost_pet_reports.*.local_id' => ['required', 'string'],
            'lost_pet_reports.*.remote_id' => ['nullable', 'string'],
            'lost_pet_reports.*.pet_local_uuid' => ['required', 'string'],
            'lost_pet_reports.*.pet_remote_id' => ['nullable', 'string'],
            'lost_pet_reports.*.last_seen_latitude' => ['required', 'numeric'],
            'lost_pet_reports.*.last_seen_longitude' => ['required', 'numeric'],
            'lost_pet_reports.*.details' => ['required', 'string'],
            'lost_pet_reports.*.disappearance_date' => ['required', 'date_format:Y-m-d H:i:s'],
            'lost_pet_reports.*.photo_url' => ['nullable', 'string', 'max:500'],
            'lost_pet_reports.*.phone' => ['required', 'string', 'max:64'],
            'lost_pet_reports.*.comments' => ['sometimes', 'array'],
            'lost_pet_reports.*.sync_status' => ['nullable', 'string', 'max:32'],
            'lost_pet_reports.*.last_modified_at' => ['required', 'date_format:Y-m-d H:i:s'],
        ];
    }
}
