<?php

namespace App\Http\Requests\Reports;

use Illuminate\Foundation\Http\FormRequest;

class SyncFoundPetReportsRequest extends FormRequest
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
            'found_pet_reports' => ['required', 'array'],
            'found_pet_reports.*.local_id' => ['required', 'string'],
            'found_pet_reports.*.remote_id' => ['nullable', 'string'],
            'found_pet_reports.*.pet_local_uuid' => ['nullable', 'string'],
            'found_pet_reports.*.matched_lost_pet_report_id' => ['nullable', 'integer'],
            'found_pet_reports.*.latitude' => ['required', 'numeric'],
            'found_pet_reports.*.longitude' => ['required', 'numeric'],
            'found_pet_reports.*.details' => ['required', 'string'],
            'found_pet_reports.*.found_date' => ['required', 'date_format:Y-m-d H:i:s'],
            'found_pet_reports.*.photo_url' => ['nullable', 'string', 'max:500'],
            'found_pet_reports.*.phone' => ['nullable', 'string', 'max:64'],
            'found_pet_reports.*.comments' => ['sometimes', 'array'],
            'found_pet_reports.*.sync_status' => ['nullable', 'string', 'max:32'],
            'found_pet_reports.*.last_modified_at' => ['required', 'date_format:Y-m-d H:i:s'],
        ];
    }
}
