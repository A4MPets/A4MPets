<?php

namespace App\Http\Requests\Reports;

use Illuminate\Foundation\Http\FormRequest;

class SyncGenericReportsRequest extends FormRequest
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
            'generic_reports' => ['required', 'array'],
            'generic_reports.*.local_id' => ['required', 'string'],
            'generic_reports.*.remote_id' => ['nullable', 'string'],
            'generic_reports.*.latitude' => ['required', 'numeric'],
            'generic_reports.*.longitude' => ['required', 'numeric'],
            'generic_reports.*.description' => ['required', 'string'],
            'generic_reports.*.reported_date' => ['required', 'date_format:Y-m-d H:i:s'],
            'generic_reports.*.risk_level_code' => ['required', 'string'],
            'generic_reports.*.photo_url' => ['nullable', 'string', 'max:500'],
            'generic_reports.*.sync_status' => ['nullable', 'string', 'max:32'],
            'generic_reports.*.last_modified_at' => ['required', 'date_format:Y-m-d H:i:s'],
        ];
    }
}
