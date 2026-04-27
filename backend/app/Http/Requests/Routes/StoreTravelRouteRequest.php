<?php

namespace App\Http\Requests\Routes;

use Illuminate\Foundation\Http\FormRequest;

class StoreTravelRouteRequest extends FormRequest
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
            'name' => ['required', 'string', 'max:255'],
            'points_json' => ['required', 'string'],
        ];
    }
}
