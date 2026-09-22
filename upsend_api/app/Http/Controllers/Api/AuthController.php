<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'no_hp' => 'required|unique:users,no_hp',
            'password' => 'required|min:6',
            'home_location_id' => 'nullable',
        ]);

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'no_hp' => $request->no_hp,
            'password' => Hash::make($request->password),
            'role' => 'karyawan',
            'home_location_id' => $request->home_location_id,
            'is_active' => true,
        ]);

        return response()->json([
            'message' => 'Registrasi berhasil.',
            'user' => $user,
        ], 201);
    }

    // Login universal — satu endpoint untuk mobile & web.
    // Field 'no_hp' dipakai sebagai identifier umum, isinya bisa:
    // email, nomor HP, atau employee_id. Dicocokkan otomatis.
    // (Nama field tetap 'no_hp' supaya sinkron dengan Flutter
    // yang mengirim AuthLoginRequested(noHp: identifier, ...))
    public function login(Request $request)
    {
        $request->validate([
            'no_hp' => 'required',
            'password' => 'required',
        ]);

        $identifier = trim($request->no_hp);

        $user = User::where('email', $identifier)
            ->orWhere('no_hp', $identifier)
            ->orWhere('employee_id', $identifier)
            ->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            return response()->json([
                'message' => 'Email/No. HP/ID Karyawan atau password salah.',
            ], 401);
        }

        if (! $user->is_active) {
            return response()->json(['message' => 'Akun sudah dinonaktifkan.'], 403);
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'user' => $user->load('homeLocation'),
            'token' => $token,
        ]);
    }

    public function loginWeb(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        $user = User::where('email', trim($request->email))->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            return response()->json([
                'message' => 'Email atau password salah.',
            ], 401);
        }

        if (! $user->is_active) {
            return response()->json(['message' => 'Akun sudah dinonaktifkan.'], 403);
        }

        if (! in_array($user->role, ['admin', 'super_admin'], true)) {
            return response()->json([
                'message' => 'Akun ini tidak memiliki akses dashboard.',
            ], 403);
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'user' => $user->load('homeLocation'),
            'token' => $token,
        ]);
    }

    public function changePassword(Request $request)
    {
        $validated = $request->validate([
            'old_password' => 'required|string',
            'new_password' => 'required|string|min:6|confirmed',
        ]);

        $user = $request->user();

        if (! Hash::check($validated['old_password'], $user->password)) {
            return response()->json([
                'message' => 'Password lama salah.',
            ], 422);
        }

        $user->update([
            'password' => Hash::make($validated['new_password']),
        ]);

        return response()->json([
            'message' => 'Password berhasil diubah.',
            'success' => true,
        ]);
    }

    public function activateAccount(Request $request)
    {
        $data = $request->validate([
            'token' => 'required|string',
            'password' => 'required|string|min:8|confirmed',
        ]);

        $user = User::where('invitation_token', hash('sha256', $data['token']))
            ->where('invitation_expires_at', '>', now())
            ->first();

        if (!$user) {
            return response()->json(['message' => 'Link aktivasi tidak valid atau sudah kedaluwarsa.'], 422);
        }

        $user->update([
            'password' => Hash::make($data['password']),
            'is_active' => true,
            'invitation_token' => null,
            'invitation_expires_at' => null,
        ]);

        return response()->json(['message' => 'Akun berhasil diaktifkan. Silakan login.']);
    }

    public function requestPasswordReset(Request $request)
    {
        $data = $request->validate(['email' => 'required|email']);
        $user = User::where('email', trim($data['email']))->first();

        if ($user) {
            $token = Str::random(64);
            $user->update([
                'password_reset_token' => hash('sha256', $token),
                'password_reset_expires_at' => now()->addMinutes(30),
            ]);
            $resetUrl = rtrim((string) env('FRONTEND_URL', 'http://localhost:5173'), '/')
                . '/reset-password?token=' . urlencode($token);
            app(\App\Services\EmailDeliveryService::class)->send(
                $user->email,
                'Reset Password Upsend',
                "Gunakan link berikut untuk membuat password baru:\n{$resetUrl}\n\nLink berlaku 30 menit.",
            );
        }

        return response()->json(['message' => 'Jika email terdaftar, link reset telah dikirim.']);
    }

    public function resetPassword(Request $request)
    {
        $data = $request->validate([
            'token' => 'required|string',
            'password' => 'required|string|min:8|confirmed',
        ]);
        $user = User::where('password_reset_token', hash('sha256', $data['token']))
            ->where('password_reset_expires_at', '>', now())
            ->first();

        if (!$user) {
            return response()->json(['message' => 'Link reset tidak valid atau sudah kedaluwarsa.'], 422);
        }

        $user->update([
            'password' => Hash::make($data['password']),
            'is_active' => true,
            'password_reset_token' => null,
            'password_reset_expires_at' => null,
        ]);

        return response()->json(['message' => 'Password berhasil diubah.']);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Berhasil logout.']);
    }

    public function me(Request $request)
    {
        return response()->json($request->user()->load('homeLocation'));
    }
}