<?php

namespace App\Http\Requests\Reports;

use Illuminate\Foundation\Http\FormRequest;

class StoreLostPetReportRequest extends FormRequest
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
            'local_id' => ['required', 'string'],
            'last_seen_latitude' => ['required', 'numeric'],
            'last_seen_longitude' => ['required', 'numeric'],
            'name' => ['required', 'string', 'max:255'],
            'details' => ['required', 'string'],
            'disappearance_date' => ['required', 'date'],
            'photo_url' => ['required', 'string', 'max:500'],
            'phone' => ['required', 'string', 'max:64'],
        ];
    }
}
