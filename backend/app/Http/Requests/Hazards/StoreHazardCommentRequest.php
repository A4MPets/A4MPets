<?php

namespace App\Http\Requests\Hazards;

use Illuminate\Foundation\Http\FormRequest;

class StoreHazardCommentRequest extends FormRequest
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
            'comment_text' => ['required', 'string', 'max:2000'],
            'author_name' => ['nullable', 'string', 'max:100'],
            'author_avatar_url' => ['nullable', 'string', 'max:500'],
            'is_anonymous' => ['sometimes', 'boolean'],
            'created_at' => ['nullable'],
        ];
    }
}
