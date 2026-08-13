<?php

namespace Database\Seeders;

use App\Models\LeaveType;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Seed Leave Types
        $leaveTypes = [
            ['name' => 'Cuti Tahunan'],
            ['name' => 'Cuti Sakit'],
            ['name' => 'Cuti Penting'],
        ];

        foreach ($leaveTypes as $type) {
            LeaveType::firstOrCreate($type);
        }
    }
}
