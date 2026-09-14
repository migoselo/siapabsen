<?php

namespace Tests\Feature;

use App\Models\Payroll;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PayrollApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_list_payroll_records_for_current_tenant(): void
    {
        $admin = User::create([
            'name' => 'Admin Payroll',
            'email' => 'admin-payroll@example.com',
            'no_hp' => '081234567890',
            'password' => bcrypt('password123'),
            'role' => 'admin',
            'is_active' => true,
            'tenant_id' => 1,
            'employee_id' => 'EMP-1-20260101-1000',
        ]);

        $user = User::create([
            'name' => 'Karyawan Gaji',
            'email' => 'pegawai-gaji@example.com',
            'no_hp' => '081234567891',
            'password' => bcrypt('password123'),
            'role' => 'karyawan',
            'is_active' => true,
            'tenant_id' => 1,
            'employee_id' => 'EMP-1-20260101-1001',
        ]);

        Payroll::create([
            'tenant_id' => 1,
            'user_id' => $user->id,
            'payroll_period' => '2026-09-01',
            'basic_salary' => 12000000,
            'transport_allowance' => 2000000,
            'meal_allowance' => 1500000,
            'attendance_allowance' => 500000,
            'other_allowance' => 250000,
            'tax_deduction' => 300000,
            'other_deduction' => 200000,
            'bank_name' => 'Bank Mandiri',
            'bank_account_name' => 'Karyawan Gaji',
            'bank_account_number' => '1234567890',
        ]);

        $response = $this->actingAs($admin, 'sanctum')->getJson('/api/payrolls');

        $response->assertOk()
            ->assertJsonPath('data.0.user.name', 'Karyawan Gaji')
            ->assertJsonPath('data.0.basic_salary', 12000000);
    }

    public function test_admin_can_create_payroll_for_employee(): void
    {
        $admin = User::create([
            'name' => 'Admin Payroll',
            'email' => 'admin-payroll-create@example.com',
            'no_hp' => '081234567892',
            'password' => bcrypt('password123'),
            'role' => 'admin',
            'is_active' => true,
            'tenant_id' => 1,
            'employee_id' => 'EMP-1-20260101-1002',
        ]);

        $user = User::create([
            'name' => 'Karyawan Baru',
            'email' => 'pegawai-baru@example.com',
            'no_hp' => '081234567893',
            'password' => bcrypt('password123'),
            'role' => 'karyawan',
            'is_active' => true,
            'tenant_id' => 1,
            'employee_id' => 'EMP-1-20260101-1003',
        ]);

        $response = $this->actingAs($admin, 'sanctum')->postJson('/api/payrolls', [
            'user_id' => $user->id,
            'payroll_period' => '2026-09-01',
            'basic_salary' => 11000000,
            'transport_allowance' => 1800000,
            'meal_allowance' => 1200000,
            'attendance_allowance' => 500000,
            'other_allowance' => 250000,
            'tax_deduction' => 280000,
            'other_deduction' => 150000,
            'bank_name' => 'BRI',
            'bank_account_name' => 'Karyawan Baru',
            'bank_account_number' => '7654321',
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.user.name', 'Karyawan Baru')
            ->assertJsonPath('data.basic_salary', 11000000);

        $this->assertDatabaseHas('payrolls', [
            'user_id' => $user->id,
            'payroll_period' => '2026-09-01',
            'basic_salary' => '11000000.00',
        ]);
    }

    public function test_missing_attendance_record_has_no_fake_check_in_time(): void
    {
        $user = User::create([
            'name' => 'Karyawan Lupa Absen',
            'email' => 'pegawai-lupa@example.com',
            'no_hp' => '081234567894',
            'password' => bcrypt('password123'),
            'role' => 'karyawan',
            'is_active' => true,
            'tenant_id' => 1,
            'employee_id' => 'EMP-1-20260101-1004',
        ]);

        $response = $this->actingAs($user, 'sanctum')->getJson('/api/attendances/my-history?start_date=2026-09-01&end_date=2026-09-30');

        $response->assertOk();
        $response->assertJsonPath('data.0.check_in_time', null);
        $response->assertJsonPath('data.0.status', 'alpha');
    }
}
