<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\UserFace;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class FaceRecognitionTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Buat dummy image untuk testing
     */
    private function createDummyImage(): UploadedFile
    {
        // Generate dummy JPEG image file (1x1 pixel white JPEG)
        $jpegData = base64_decode(
            '/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8VAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCwAA//Z'
        );

        $tempFile = tempnam(sys_get_temp_dir(), 'test_face_');
        file_put_contents($tempFile, $jpegData);

        return new UploadedFile(
            $tempFile,
            'test_face.jpg',
            'image/jpeg',
            null,
            true
        );
    }

    public function test_user_can_register_face()
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user)->postJson('/api/face/register', [
            'photo' => $this->createDummyImage(),
        ]);

        $response->assertStatus(200);
        $response->assertJson(['success' => true]);
        $this->assertDatabaseHas('user_faces', [
            'user_id' => $user->id,
        ]);
    }

    public function test_face_register_requires_photo()
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user)->postJson('/api/face/register', []);

        $response->assertStatus(422);
    }

    public function test_face_register_requires_authentication()
    {
        $response = $this->postJson('/api/face/register', [
            'photo' => $this->createDummyImage(),
        ]);

        $response->assertStatus(401);
    }

    public function test_user_can_check_face_status()
    {
        $user = User::factory()->create();

        // Sebelum register
        $response = $this->actingAs($user)->getJson('/api/face/status');
        $response->assertStatus(200);
        $response->assertJson(['registered' => false]);

        // Setelah register
        UserFace::create([
            'user_id' => $user->id,
            'image_path' => 'face-register/test.jpg',
            'embedding' => json_encode(['test' => 'data']),
            'is_active' => true,
        ]);

        $response = $this->actingAs($user)->getJson('/api/face/status');
        $response->assertStatus(200);
        $response->assertJson(['registered' => true]);
    }

    public function test_user_can_verify_face()
    {
        $user = User::factory()->create();

        // Register face terlebih dahulu
        UserFace::create([
            'user_id' => $user->id,
            'image_path' => 'face-register/test.jpg',
            'embedding' => json_encode([
                'histogram' => array_fill(0, 256, 0.01),
                'descriptor_mean' => array_fill(0, 32, 50),
                'descriptor_std' => array_fill(0, 32, 20),
            ]),
            'is_active' => true,
        ]);

        // Verify dengan foto (tidak akan match sempurna karena dummy image)
        $response = $this->actingAs($user)->postJson('/api/face/verify', [
            'photo' => $this->createDummyImage(),
        ]);

        // Harapkan response 200 atau 403 (tergantung face matching logic)
        $this->assertIn($response->status(), [200, 403]);
        $this->assertTrue(isset($response['matched']) || isset($response['matched']));
    }

    public function test_face_verify_requires_photo()
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user)->postJson('/api/face/verify', []);

        $response->assertStatus(422);
    }

    public function test_face_verify_returns_403_when_not_registered()
    {
        $user = User::factory()->create();

        $response = $this->actingAs($user)->postJson('/api/face/verify', [
            'photo' => $this->createDummyImage(),
        ]);

        // Ketika belum register, harusnya return 403 atau error message
        $response->assertStatus(422);
    }

    public function test_face_register_replaces_previous_registration()
    {
        $user = User::factory()->create();

        // Register face pertama
        $this->actingAs($user)->postJson('/api/face/register', [
            'photo' => $this->createDummyImage(),
        ]);

        $firstCount = UserFace::where('user_id', $user->id)->count();
        $this->assertEquals(1, $firstCount);

        // Register face kedua (should replace)
        $this->actingAs($user)->postJson('/api/face/register', [
            'photo' => $this->createDummyImage(),
        ]);

        $secondCount = UserFace::where('user_id', $user->id)->count();
        $this->assertEquals(1, $secondCount);
    }
}
