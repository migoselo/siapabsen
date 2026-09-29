<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\LeaveRequest;
use App\Models\LeaveBalance;
use App\Models\LeaveType;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
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

    public function test_admin_leave_requests_include_requesters_home_location(): void
    {
        if (!Schema::hasTable('locations')) {
            Schema::create('locations', function (Blueprint $table): void {
                $table->id();
                $table->string('name');
            });
        }

        $locationId = DB::table('locations')->insertGetId(['name' => 'Kantor Pusat']);
        $divisionId = DB::table('divisions')->insertGetId([
            'tenant_id' => 1,
            'name' => 'Engineering',
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        $user = User::create([
            'name' => 'Admin Test',
            'email' => 'admin@example.com',
            'password' => bcrypt('password123'),
            'role' => 'super_admin',
            'tenant_id' => 1,
            'home_location_id' => $locationId,
            'division_id' => $divisionId,
            'is_active' => true,
        ]);

        LeaveRequest::create([
            'user_id' => $user->id,
            'type' => 'Cuti Tahunan',
            'start_date' => '2026-09-30',
            'end_date' => '2026-09-30',
            'total_days' => 1,
            'reason' => 'Keperluan keluarga',
            'status' => 'pending',
        ]);

        $this->actingAs($user, 'sanctum')
            ->getJson('/api/admin/leave-requests')
            ->assertOk()
            ->assertJsonPath('data.0.requester.name', 'Admin Test')
            ->assertJsonPath('data.0.requester.departmentId', $divisionId)
            ->assertJsonPath('data.0.requester.departmentName', 'Engineering')
            ->assertJsonPath('data.0.requester.locationName', 'Kantor Pusat');
    }
}
