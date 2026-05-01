<?php

namespace App\Http\Requests\Reports;

use Illuminate\Foundation\Http\FormRequest;

class UpdateGenericReportRequest extends FormRequest
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
            'latitude' => ['required', 'numeric'],
            'longitude' => ['required', 'numeric'],
            'description' => ['required', 'string'],
            'reported_date' => ['required', 'date'],
            'risk_level_code' => ['required', 'string'],
            'impact_radius_meters' => ['sometimes', 'numeric', 'min:0', 'max:10000'],
            'photo_url' => ['nullable', 'string', 'max:500'],
        ];
    }
}
