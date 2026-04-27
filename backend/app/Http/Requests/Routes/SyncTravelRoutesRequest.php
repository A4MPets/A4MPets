<?php

namespace App\Http\Requests\Routes;

use Illuminate\Foundation\Http\FormRequest;

class SyncTravelRoutesRequest extends FormRequest
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
            'routes' => ['required', 'array'],
            'routes.*.local_id' => ['required', 'string'],
            'routes.*.remote_id' => ['nullable', 'string'],
            'routes.*.name' => ['required', 'string', 'max:255'],
            'routes.*.points_json' => ['required', 'string'],
            'routes.*.sync_status' => ['required', 'string', 'max:32'],
            'routes.*.last_modified_at' => ['required', 'date_format:Y-m-d H:i:s'],
        ];
    }
}
