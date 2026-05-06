<?php

namespace Database\Factories;

use App\Models\Pet;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class PetFactory extends Factory
{
    protected $model = Pet::class;

    public function definition(): array
    {
        return [
            'user_id'       => User::factory(),
            'name'          => $this->faker->firstName() . ' (QA)',
            'status'        => 'normal',
            'is_ownerless'  => false,
            'total_walks'   => $this->faker->numberBetween(0, 100),
            'registered_at' => now(),
        ];
    }

    public function lost(): static
    {
        return $this->state(['status' => 'perdida']);
    }

    public function ownerless(): static
    {
        return $this->state(['user_id' => null, 'is_ownerless' => true]);
    }
}
