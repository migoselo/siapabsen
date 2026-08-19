<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\LeaveBalance;
use App\Models\LeaveType;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class LeaveRequestTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_create_leave_request(): void
    {
        $user = User::create([
            'name' => 'Karyawan Test',
            'email' => 'karyawan@example.com',
            'no_hp' => '081234567890',
            'password' => bcrypt('password123'),
            'role' => 'karyawan',
            'is_active' => true,
        ]);

        $this->actingAs($user, 'sanctum');

        $leaveType = LeaveType::create(['name' => 'Cuti Tahunan']);
        LeaveBalance::create([
            'user_id' => $user->id,
            'leave_type_id' => $leaveType->id,
            'year' => 2026,
            'quota_days' => 12,
            'used_days' => 0,
        ]);

        $response = $this->postJson('/api/leave-requests', [
            'type' => 'Cuti Tahunan',
            'start_date' => '2026-08-20',
            'end_date' => '2026-08-22',
            'reason' => 'Liburan keluarga',
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('user_id', $user->id)
            ->assertJsonPath('type', 'Cuti Tahunan')
            ->assertJsonPath('status', 'pending');

        $this->assertDatabaseHas('leave_requests', [
            'user_id' => $user->id,
            'type' => 'Cuti Tahunan',
            'reason' => 'Liburan keluarga',
            'status' => 'pending',
        ]);

        $this->assertDatabaseHas('leave_balances', [
            'user_id' => $user->id,
            'leave_type_id' => $leaveType->id,
            'used_days' => 3,
        ]);
    }
}
