<?php

namespace Database\Factories;

use App\Models\HazardReport;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class HazardReportFactory extends Factory
{
    protected $model = HazardReport::class;

    public function definition(): array
    {
        return [
            'user_id'                 => User::factory(),
            'incident_latitude'       => $this->faker->latitude(4.0, 5.5),
            'incident_longitude'      => $this->faker->longitude(-75.0, -74.5),
            'impact_radius_meters'    => 100,
            'description'             => $this->faker->sentence(),
            'narrative_description'   => $this->faker->sentence(),
            'reported_by_username'    => $this->faker->userName(),
            'risk_level_code'         => 'medium',
            'category_code'           => 'pest_presence',
            'estimated_duration_code' => '1_week',
            'status'                  => 'created',
            'reported_at'             => now(),
        ];
    }
}
