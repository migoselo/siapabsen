<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

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

    // Login lama — dipakai mobile, pakai no_hp. TIDAK DIUBAH.
    public function login(Request $request)
    {
        $request->validate([
            'no_hp' => 'required',
            'password' => 'required',
        ]);

        $user = User::where('no_hp', $request->no_hp)->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            return response()->json(['message' => 'Nomor HP atau password salah.'], 401);
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

    // Login baru — khusus dashboard web, pakai email.
    public function loginWeb(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        $user = User::where('email', $request->email)->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            return response()->json(['message' => 'Email atau password salah.'], 401);
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