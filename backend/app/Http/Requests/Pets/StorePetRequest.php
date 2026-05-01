<?php

namespace App\Http\Requests\Pets;

use Illuminate\Foundation\Http\FormRequest;

class StorePetRequest extends FormRequest
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
            'photo_path' => ['nullable', 'string', 'max:500'],
        ];
    }
}
