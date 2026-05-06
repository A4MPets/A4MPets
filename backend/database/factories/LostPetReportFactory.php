<?php

namespace Database\Factories;

use App\Models\LostPetReport;
use App\Models\Pet;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class LostPetReportFactory extends Factory
{
    protected $model = LostPetReport::class;

    public function definition(): array
    {
        return [
            'user_id'             => User::factory(),
            'pet_id'              => Pet::factory(),
            'last_seen_latitude'  => $this->faker->latitude(4.0, 5.5),
            'last_seen_longitude' => $this->faker->longitude(-75.0, -74.5),
            'details'             => $this->faker->sentence(),
            'disappearance_date'  => now()->subDays(2),
            'phone'               => $this->faker->phoneNumber(),
        ];
    }
}
