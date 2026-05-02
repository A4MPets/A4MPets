<?php

namespace App\Http\Requests\Reports;

use Illuminate\Foundation\Http\FormRequest;

class UpdateLostPetReportRequest extends FormRequest
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
            'pet_id' => ['required', 'integer'],
            'last_seen_latitude' => ['required', 'numeric'],
            'last_seen_longitude' => ['required', 'numeric'],
            'details' => ['required', 'string'],
            'disappearance_date' => ['required', 'date'],
            'photo_url' => ['nullable', 'string', 'max:500'],
            'phone' => ['required', 'string', 'max:64'],
        ];
    }
}
