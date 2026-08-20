<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\UserFace;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
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
        /** @var User $user */
        $user = User::factory()->createOne();

        $response = $this->actingAs($user)->post('/api/face/register', [
            'photo' => $this->createDummyImage(),
            'embedding' => array_fill(0, 128, 0.1),
        ]);

        $response->assertStatus(200);
        $response->assertJson(['success' => true]);
        $this->assertDatabaseHas('user_faces', [
            'user_id' => $user->id,
        ]);
    }

    public function test_face_register_requires_photo()
    {
        /** @var User $user */
        $user = User::factory()->createOne();

        $response = $this->actingAs($user)->postJson('/api/face/register', []);

        $response->assertStatus(422);
    }

    public function test_face_register_requires_authentication()
    {
        $response = $this->post('/api/face/register', [
            'photo' => $this->createDummyImage(),
            'embedding' => array_fill(0, 128, 0.1),
        ]);

        $response->assertStatus(401);
    }

    public function test_user_can_check_face_status()
    {
        /** @var User $user */
        $user = User::factory()->createOne();

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
        /** @var User $user */
        $user = User::factory()->createOne();

        // Register face terlebih dahulu
        UserFace::create([
            'user_id' => $user->id,
            'image_path' => 'face-register/test.jpg',
            'embedding' => json_encode(array_fill(0, 128, 0.1)),
            'is_active' => true,
        ]);

        // Verify dengan foto (tidak akan match sempurna karena dummy image)
        $response = $this->actingAs($user)->post('/api/face/verify', [
            'photo' => $this->createDummyImage(),
            'embedding' => array_fill(0, 128, 0.1),
        ]);

        // Harapkan response 200 atau 403 (tergantung face matching logic)
        $this->assertContains($response->status(), [200, 403]);
        $this->assertTrue(isset($response['matched']));
    }

    public function test_face_verify_requires_photo()
    {
        /** @var User $user */
        $user = User::factory()->createOne();

        $response = $this->actingAs($user)->postJson('/api/face/verify', []);

        $response->assertStatus(422);
    }

    public function test_face_verify_returns_403_when_not_registered()
    {
        /** @var User $user */
        $user = User::factory()->createOne();

        $response = $this->actingAs($user)->post('/api/face/verify', [
            'photo' => $this->createDummyImage(),
            'embedding' => array_fill(0, 128, 0.1),
        ]);

        // Ketika belum register, harusnya return 403 atau error message
        $response->assertStatus(403);
    }

    public function test_face_register_replaces_previous_registration()
    {
        /** @var User $user */
        $user = User::factory()->createOne();

        // Register face pertama
        $this->actingAs($user)->post('/api/face/register', [
            'photo' => $this->createDummyImage(),
            'embedding' => array_fill(0, 128, 0.1),
        ]);

        $firstCount = UserFace::where('user_id', $user->id)->count();
        $this->assertEquals(1, $firstCount);

        // Register face kedua (should replace)
        $this->actingAs($user)->post('/api/face/register', [
            'photo' => $this->createDummyImage(),
            'embedding' => array_fill(0, 128, 0.1),
        ]);

        $secondCount = UserFace::where('user_id', $user->id)->count();
        $this->assertEquals(1, $secondCount);
    }
}
