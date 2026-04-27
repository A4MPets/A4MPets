<?php

namespace App\Http\Requests\Pets;

use Illuminate\Foundation\Http\FormRequest;

class SyncPetsRequest extends FormRequest
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
            'pets' => ['required', 'array'],
            'pets.*.local_id' => ['required', 'string'],
            'pets.*.remote_id' => ['nullable', 'string'],
            'pets.*.name' => ['required', 'string', 'max:255'],
            'pets.*.photo_path' => ['nullable', 'string', 'max:500'],
            'pets.*.sync_status' => ['required', 'string', 'max:32'],
            'pets.*.last_modified_at' => ['required', 'date_format:Y-m-d H:i:s'],
        ];
    }
}
