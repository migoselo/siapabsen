<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_web_login_uses_the_same_contract_as_mobile_login(): void
    {
        $user = User::create([
            'name' => 'Admin Test',
            'email' => 'admin@example.com',
            'no_hp' => '081234567890',
            'password' => bcrypt('password123'),
            'role' => 'admin',
            'is_active' => true,
        ]);

        $response = $this->postJson('/api/login-web', [
            'no_hp' => $user->email,
            'password' => 'password123',
        ]);

        $response->assertOk()
            ->assertJsonStructure(['user', 'token'])
            ->assertJsonPath('user.id', $user->id);
    }

    public function test_authenticated_user_can_change_password(): void
    {
        $user = User::create([
            'name' => 'Karyawan Test',
            'email' => 'karyawan@example.com',
            'no_hp' => '081234567891',
            'password' => bcrypt('password123'),
            'role' => 'karyawan',
            'is_active' => true,
        ]);

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/change-password', [
            'old_password' => 'password123',
            'new_password' => 'newpassword123',
            'new_password_confirmation' => 'newpassword123',
        ]);

        $response->assertOk()
            ->assertJson(['message' => 'Password berhasil diubah.']);

        $this->assertTrue(password_verify('newpassword123', $user->fresh()->password));
    }
}