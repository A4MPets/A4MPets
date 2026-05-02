<?php

namespace App\Http\Requests\Reports;

use Illuminate\Foundation\Http\FormRequest;

class StoreFoundPetReportRequest extends FormRequest
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
            'pet_id' => ['nullable', 'integer'],
            'matched_lost_pet_report_id' => ['nullable', 'integer'],
            'latitude' => ['required', 'numeric'],
            'longitude' => ['required', 'numeric'],
            'details' => ['required', 'string'],
            'found_date' => ['required', 'date'],
            'photo_url' => ['nullable', 'string', 'max:500'],
            'phone' => ['nullable', 'string', 'max:64'],
        ];
    }
}
