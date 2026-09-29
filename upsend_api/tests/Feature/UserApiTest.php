<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class UserApiTest extends TestCase
{
	use RefreshDatabase;

	public function test_employee_registration_rejects_email_already_used_by_another_tenant(): void
	{
		$admin = User::create([
			'name' => 'Admin Perusahaan',
			'email' => 'admin@example.com',
			'no_hp' => '081234567890',
			'password' => bcrypt('password123'),
			'role' => 'admin',
			'is_active' => true,
			'tenant_id' => 1,
			'employee_id' => 'EMP-1-20260929-1000',
		]);

		User::create([
			'name' => 'Karyawan Terdaftar',
			'email' => 'pegawai@example.com',
			'no_hp' => '081234567891',
			'password' => bcrypt('password123'),
			'role' => 'karyawan',
			'is_active' => true,
			'tenant_id' => 2,
			'employee_id' => 'EMP-2-20260929-1000',
		]);

		$response = $this->actingAs($admin, 'sanctum')->postJson('/api/users', [
			'name' => 'Karyawan Duplikat',
			'email' => ' Pegawai@Example.com ',
			'role' => 'karyawan',
		]);

		$response->assertUnprocessable()
			->assertJsonValidationErrors('email');

		$this->assertSame(1, User::where('email', 'pegawai@example.com')->count());
	}

	public function test_employee_registration_does_not_modify_an_existing_pending_account(): void
	{
		$admin = User::create([
			'name' => 'Admin Perusahaan',
			'email' => 'admin-pending@example.com',
			'no_hp' => '081234567892',
			'password' => bcrypt('password123'),
			'role' => 'admin',
			'is_active' => true,
			'tenant_id' => 1,
			'employee_id' => 'EMP-1-20260929-1001',
		]);

		User::create([
			'name' => 'Nama Lama',
			'email' => 'pending@example.com',
			'no_hp' => '081234567893',
			'password' => bcrypt('password123'),
			'role' => 'karyawan',
			'is_active' => false,
			'tenant_id' => 1,
			'employee_id' => 'EMP-1-20260929-1002',
		]);

		$response = $this->actingAs($admin, 'sanctum')->postJson('/api/users', [
			'name' => 'Nama Pengganti',
			'email' => 'pending@example.com',
			'role' => 'karyawan',
		]);

		$response->assertUnprocessable()->assertJsonValidationErrors('email');
		$this->assertSame(1, User::where('email', 'pending@example.com')->count());
		$this->assertDatabaseHas('users', [
			'email' => 'pending@example.com',
			'name' => 'Nama Lama',
			'is_active' => false,
		]);
	}

	public function test_email_availability_endpoint_reports_existing_and_new_addresses(): void
	{
		$admin = User::create([
			'name' => 'Admin Cek Email',
			'email' => 'admin-check@example.com',
			'no_hp' => '081234567894',
			'password' => bcrypt('password123'),
			'role' => 'admin',
			'is_active' => true,
			'tenant_id' => 1,
			'employee_id' => 'EMP-1-20260929-1003',
		]);

		User::create([
			'name' => 'Karyawan Existing',
			'email' => 'existing@example.com',
			'no_hp' => '081234567895',
			'password' => bcrypt('password123'),
			'role' => 'karyawan',
			'is_active' => false,
			'tenant_id' => 1,
			'employee_id' => 'EMP-1-20260929-1004',
		]);

		$this->actingAs($admin, 'sanctum')
			->getJson('/api/users/email-availability?email=EXISTING%40EXAMPLE.COM')
			->assertOk()
			->assertJsonPath('available', false);

		$this->actingAs($admin, 'sanctum')
			->getJson('/api/users/email-availability?email=new%40example.com')
			->assertOk()
			->assertJsonPath('available', true);
	}
}
