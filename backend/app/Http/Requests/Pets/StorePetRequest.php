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
            'name' => ['nullable', 'string', 'max:255'],
            'photo_path' => ['nullable', 'string', 'max:500'],
            'total_walks' => ['nullable', 'integer', 'min:0'],
            'registered_at' => ['nullable', 'date'],
            'adoption_date' => ['nullable', 'date'],
            'birth_date' => ['nullable', 'date'],
            'status' => ['nullable', 'in:normal,lost,perdida'],
            'is_ownerless' => ['nullable', 'boolean'],
        ];
    }
}
